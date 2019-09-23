require 'spec_helper'

describe 'SplunkTracing::Scope' do
  let(:manager) { instance_spy(SplunkTracing::ScopeManager) }

  describe '#span' do
    it 'should return the scoped span' do
      expected = instance_spy(SplunkTracing::Span)
      scope = SplunkTracing::Scope.new(manager: manager, span: expected)
      expect(scope.span).to eq(expected)
    end
  end

  describe '#close' do
    it 'should close the scope' do
      scope = SplunkTracing::Scope.new(manager: manager, span: instance_spy(SplunkTracing::Span))
      expect { scope.close }.not_to raise_error
      expect { scope.close }.to raise_error(SplunkTracing::Error, 'already closed')
    end

    it 'should finish the span' do
      span = instance_spy(SplunkTracing::Span)
      scope = SplunkTracing::Scope.new(manager: manager, span: span)
      expect(span).to receive(:finish)
      scope.close
    end

    context 'when the scope should not finish on close' do
      let(:span) { instance_spy(SplunkTracing::Span) }
      let(:scope) { SplunkTracing::Scope.new(manager: manager, span: span, finish_on_close: false) }

      it 'should not close the scope' do
        expect(span).not_to receive(:finish)
        scope.close
      end
    end
  end
end
