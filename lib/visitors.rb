# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module AcceptsVisitorMixin
  def accept(visitor)
    visitor.public_send(visiting_method_for_self, self)
  end

  private

  def visiting_method_for_self
    @visiting_method_for_self ||= "visit_#{self.class.name.demodulize.underscore}".to_sym
  end
end
