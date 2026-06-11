module NLP
  class Pipeline < ApplicationService
    def initialize(text, chat_id:)
      @text = text
      @chat_id = chat_id
    end

    def call
      intent_result = NLP::DetectIntent.call(@text)
      return intent_result unless intent_result.success?

      intent = intent_result.data[:intent]

      entities_result = NLP::ExtractEntities.call(@text, intent: intent)
      return entities_result unless entities_result.success?

      NLP::ExecuteIntent.call(
        intent: intent,
        entities: entities_result.data,
        chat_id: @chat_id
      )
    end
  end
end
