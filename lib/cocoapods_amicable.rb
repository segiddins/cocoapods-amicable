# frozen_string_literal: true

module CocoaPodsAmicable
  module TargetIntegratorMixin
    def add_check_manifest_lock_script_phase
      podfile = target.target_definition.podfile
      return super unless podfile.plugins.key?('cocoapods-amicable')

      phase_name = Pod::Installer::UserProjectIntegrator::TargetIntegrator::CHECK_MANIFEST_PHASE_NAME
      native_targets.each do |native_target|
        phase = Pod::Installer::UserProjectIntegrator::TargetIntegrator.create_or_update_build_phase(native_target, Pod::Installer::UserProjectIntegrator::TargetIntegrator::BUILD_PHASE_PREFIX + phase_name)
        native_target.build_phases.unshift(phase).uniq! unless native_target.build_phases.first == phase

        phase.shell_script = <<-SH
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

        phase.input_paths = %w[
          ${PODS_PODFILE_DIR_PATH}/Podfile.lock
          ${PODS_ROOT}/Manifest.lock
          ${PODS_ROOT}/Podfile.sha1
        ]
        if name = podfile.defined_in_file && podfile.defined_in_file.basename
          phase.input_paths << "${PODS_PODFILE_DIR_PATH}/#{name}"
        end
        phase.output_paths = [target.check_manifest_lock_script_output_file_path]
      end
    end
  end

  module InstallerMixin
    def write_lockfiles
      super
      return unless podfile.plugins.key?('cocoapods-amicable')
      return unless checksum = podfile.checksum
      return unless podfile_path = podfile.defined_in_file
      checksum_path = sandbox.root + 'Podfile.sha1'

      Pod::UI.message "- Writing Podfile checksum in #{Pod::UI.path checksum_path}" do
        checksum_path.open('w') { |f| f << checksum << '  ' << podfile_path.basename.to_s << "\n" }
      end
    end
  end

  module LockfileMixin
    def generate(podfile, *)
      lockfile = super
      lockfile.internal_data.delete('PODFILE CHECKSUM') if podfile.plugins.key?('cocoapods-amicable')
      lockfile
    end
  end
end


module Pod
  class Installer
    prepend ::CocoaPodsAmicable::InstallerMixin

    class UserProjectIntegrator
      class TargetIntegrator
        prepend ::CocoaPodsAmicable::TargetIntegratorMixin
      end
    end
  end

  class Lockfile
    class << self
      prepend ::CocoaPodsAmicable::LockfileMixin
    end
    end
end
