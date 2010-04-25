module AfterCommit
  module ActiveSupportCallbacks
    def self.included(base)
      
      base::Callback.class_eval do
        def have_callback?
          true
        end
      end
      
      base::CallbackChain.class_eval do
        def have_callback?
          any? &:have_callback?
        end
      end
      
      base.class_eval do
        def have_callback?(*callbacks)
          self.class.observers.size > 0 or
          self.class.count_observers > 0 or
          callbacks.any? do |callback|
            self.class.send("#{callback}_callback_chain").have_callback?
          end
        end
      end
      
    end
  end
end
