# frozen_string_literal: true

require 'rails_helper'

# AGENT_BOT_ONLY_OUTSIDE_WORKING_HOURS: the bot must stay silent while the inbox
# is open (humans available) and answer only when it is closed.
RSpec.describe AgentBotListener do
  let(:listener) { described_class.instance }
  let(:inbox) { instance_double(Inbox, working_hours_enabled?: true, working_now?: working_now) }
  let(:conversation) { instance_double(Conversation, id: SecureRandom.uuid, inbox: inbox) }
  let(:agent_bot_inbox) { instance_double(AgentBotInbox, processing_block_reason: nil) }
  let(:working_now) { true }

  def gate
    listener.send(:skip_for_gate?, agent_bot_inbox, conversation)
  end

  context 'when the flag is off (default)' do
    before { allow(ENV).to receive(:fetch).and_call_original }

    it 'never skips because of working hours' do
      expect(gate).to be(false)
    end
  end

  context 'when the flag is on' do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('AGENT_BOT_ONLY_OUTSIDE_WORKING_HOURS', 'false').and_return('true')
    end

    it 'skips inside working hours' do
      expect(gate).to be(true)
    end

    context 'when the inbox is closed' do
      let(:working_now) { false }

      it 'lets the bot answer' do
        expect(gate).to be(false)
      end
    end

    context 'when the inbox has working hours disabled' do
      let(:inbox) { instance_double(Inbox, working_hours_enabled?: false) }

      it 'keeps the previous behavior (bot answers)' do
        expect(gate).to be(false)
      end
    end
  end
end
