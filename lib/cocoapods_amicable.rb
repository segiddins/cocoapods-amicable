# frozen_string_literal: true

module CocoaPodsAmicable
  class PodfileChecksumFixer
    def initialize(post_install_context)
      @post_install_context = post_install_context
    end

    def fix!
      Pod::UI.titled_section 'Moving the Podfile checksum from the lockfile' do
        @checksum = remove_checksum_from_lockfiles
        write_sha1_file
        update_check_manifest_script_phases
      end
    end

    private

    attr_reader :checksum

    def sandbox
      @post_install_context.sandbox
    end

    def lockfiles
      [Pod::Config.instance.lockfile_path, sandbox.manifest_path].map do |lockfile_path|
        Pod::Lockfile.from_file(lockfile_path)
      end
    end

    def remove_checksum_from_lockfiles
      checksums = lockfiles.map do |lockfile|
        checksum = lockfile.internal_data.delete('PODFILE CHECKSUM')
        lockfile.write_to_disk(lockfile.defined_in_file)
        checksum
      end.uniq
      case checksums.size
      when 1
        checksums.first
      else
        raise 'Multiple (different) podfiles checksums found'
      end
    end

    def sha1_file_path
      sandbox.root + 'Podfile.sha1'
    end

    def podfile_basename
      File.basename(Pod::Config.instance.podfile.defined_in_file)
    end

    def write_sha1_file
      return unless name = podfile_basename
      sha1_file_path.open('w') do |f|
        f.write <<-EOS
#{checksum}  #{name}
                   EOS
      end
    end

    def update_check_manifest_script_phases
      user_projects = []
      @post_install_context.umbrella_targets.each do |umbrella_target|
        user_projects << umbrella_target.user_project
        umbrella_target.user_targets.each do |user_target|
          build_phase = user_target.build_phases.find do |bp|
            bp.name.end_with? Pod::Installer::UserProjectIntegrator::TargetIntegrator::CHECK_MANIFEST_PHASE_NAME
          end
          update_check_manifest_script_phase(build_phase)
        end
      end

      user_projects.uniq.each(&:save)
    end

    def update_check_manifest_script_phase(build_phase)
      build_phase.shell_script = <<-SH
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

      build_phase.input_paths = %w[
        ${PODS_PODFILE_DIR_PATH}/Podfile.lock
        ${PODS_ROOT}/Manifest.lock
        ${PODS_ROOT}/Podfile.sha1
      ]
      if name = podfile_basename
        build_phase.input_paths << "${PODS_PODFILE_DIR_PATH}/#{name}"
      end
    end
  end
end
