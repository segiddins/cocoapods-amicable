# frozen_string_literal: true

require 'cocoapods_amicable'

Pod::HooksManager.register 'cocoapods-amicable', :post_install do |post_install_context|
  CocoaPodsAmicable::PodfileChecksumFixer.new(post_install_context).fix!
end
