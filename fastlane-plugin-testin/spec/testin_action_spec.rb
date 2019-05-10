describe Fastlane::Actions::TestinAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The testin plugin is working!")

      Fastlane::Actions::TestinAction.run(nil)
    end
  end
end
