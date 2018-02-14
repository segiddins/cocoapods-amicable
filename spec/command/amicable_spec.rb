require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Amicable do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ amicable }).should.be.instance_of Command::Amicable
      end
    end
  end
end

