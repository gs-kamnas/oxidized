module Oxidized
  class Node
    class NodeStats
      ALL_STATUSES = %i[success failure no_connection].freeze

      def initialize
        raise OxidizedError 'Attempt to instantiate abstract node stats base class!'
      end

      def last_state_occurrence(state = :success)
        if st = get(state)
          st = st.last[:end]
        else
          st = "never"
        end
        st
      end

      def as_json(options={})
        last_states = {}
        ALL_STATUSES.each { |stat| last_states[stat] = last_state_occurrence(stat) }
        {
          "counters": get_counter(),
          "last_modified": mtime(),
          "last_states": last_states
        }
      end

      def to_json(*options)
        as_json.to_json(*options)
      end
    end
  end
end
