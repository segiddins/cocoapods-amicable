# frozen_string_literal: true

require 'cocoapods_amicable'
require 'tmpdir'

RSpec.describe CocoaPodsAmicable do
    context "with a user project" do
        around(:each) do |t|
            Dir.chdir(Dir.mktmpdir) { t.run }
        end

        let(:config) { Pod::Config.instance }

        let(:podfile_content) { <<-RUBY.strip_heredoc }
            plugin 'cocoapods-amicable'
            target 'App'
        RUBY

        before do
            user_project = Xcodeproj::Project.new('App.xcodeproj')
            Pod::Generator::AppTargetHelper.add_app_target(user_project, :osx, '10.11')
            user_project.save

            File.write 'Podfile', podfile_content

            CLAide::Command::PluginManager.load_plugins('cocoapods')
        end

        it 'writes something' do
            config.verbose = true
            installer = Pod::Installer.new(config.sandbox, config.podfile, config.lockfile)
            installer.install!

            expect(File.read('Podfile.lock')).to eq <<-YAML.strip_heredoc
                COCOAPODS: #{Pod::VERSION}
            YAML
            expect(File.read('Pods/Podfile.sha1')).to eq <<-EOS.strip_heredoc
                f81a4392854a0fca54d10ebc66e8bc82bc03281a  Podfile
            EOS

            expect(installer.aggregate_targets.flat_map(&:user_targets)).to all  satisfy { |target|
                manifest_phase = target.build_phases.find {|bp| bp.name == '[CP] Check Pods Manifest.lock' }
                expect(manifest_phase.shell_script).to eq <<-SH.strip_heredoc
                    set -e
                    set -u
                    set -o pipefail

                    fail() {
                        # print error to STDERR
                        echo "error: The sandbox is not in sync with the Podfile.lock. Run 'pod install' or update your CocoaPods installation." $@ >&2
                        exit 1
                    }

                    diff -q "${PODS_PODFILE_DIR_PATH}/Podfile.lock" "${PODS_ROOT}/Manifest.lock" > /dev/null || fail "The manifest in the sandbox differs from your lockfile."

                    if [ -f "${PODS_ROOT}/Podfile.sha1" ]; then
                        (cd "${PODS_PODFILE_DIR_PATH}" && shasum --algorithm 1 --status --check "${PODS_ROOT}/Podfile.sha1") || fail "Your Podfile has been changed since the last time you ran 'pod install'."
                    fi

                    # This output is used by Xcode 'outputs' to avoid re-running this script phase.
                    echo "SUCCESS" > "${SCRIPT_OUTPUT_FILE_0}"
                SH
                expect(manifest_phase.input_paths).to eq [
                    "${PODS_PODFILE_DIR_PATH}/Podfile.lock",
                    "${PODS_ROOT}/Manifest.lock",
                    "${PODS_ROOT}/Podfile.sha1",
                    "${PODS_PODFILE_DIR_PATH}/Podfile"
                ]
                expect(manifest_phase.output_paths).to eq %w[
                    $(DERIVED_FILE_DIR)/Pods-App-checkManifestLockResult.txt
                ]
            }

            expect(Pod::UI.output)
                .to include "Writing Podfile checksum in `Pods/Podfile.sha1`"
        end

        context 'when the plugin is not specified' do
            let(:podfile_content) { super().gsub(/plugin.+/, '') }

            it 'keeps the checksum in the lockfile' do
                config.verbose = true
                installer = Pod::Installer.new(config.sandbox, config.podfile, config.lockfile)
                installer.install!

                expect(File.read('Podfile.lock')).to eq <<-YAML.strip_heredoc
                    PODFILE CHECKSUM: 592f3ceb65a6adde4fcbc481f1e0325e951f85e5

                    COCOAPODS: #{Pod::VERSION}
                YAML
                expect(File.file?('Pods/Podfile.sha1')).to eq false

                expect(installer.aggregate_targets.flat_map(&:user_targets)).to all  satisfy { |target|
                    manifest_phase = target.build_phases.find {|bp| bp.name == '[CP] Check Pods Manifest.lock' }
                    expect(manifest_phase.shell_script).to eq <<-SH.strip_heredoc
                        diff "${PODS_PODFILE_DIR_PATH}/Podfile.lock" "${PODS_ROOT}/Manifest.lock" > /dev/null
                        if [ $? != 0 ] ; then
                            # print error to STDERR
                            echo "error: The sandbox is not in sync with the Podfile.lock. Run 'pod install' or update your CocoaPods installation." >&2
                            exit 1
                        fi
                        # This output is used by Xcode 'outputs' to avoid re-running this script phase.
                        echo "SUCCESS" > "${SCRIPT_OUTPUT_FILE_0}"
                    SH
                    expect(manifest_phase.input_paths).to eq [
                        "${PODS_PODFILE_DIR_PATH}/Podfile.lock",
                        "${PODS_ROOT}/Manifest.lock",
                    ]
                    expect(manifest_phase.output_paths).to eq %w[
                        $(DERIVED_FILE_DIR)/Pods-App-checkManifestLockResult.txt
                    ]
                }

                expect(Pod::UI.output)
                    .not_to include "Writing Podfile checksum in `Pods/Podfile.sha1`"
            end
        end
    end
end
