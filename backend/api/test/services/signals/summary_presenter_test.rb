# frozen_string_literal: true

require 'test_helper'

module Signals
  class SummaryPresenterTest < ActiveSupport::TestCase
    setup do
      @health_summary = health_summaries(:early_bird)
      @preference_profile = preference_profiles(:aligned)
      @presenter = SummaryPresenter.new(@health_summary, @preference_profile)
    end

    test 'chronotype_label' do
      assert_equal 'Early bird', @presenter.send(:chronotype_label)
    end

    test 'peak_energy_window' do
      assert_equal '08:00–10:00', @presenter.send(:peak_energy_window)
    end

    test 'routine_stability_tier' do
      assert_equal 'high', @presenter.send(:routine_stability_tier)
    end

    test 'activity_tier' do
      assert_equal 'moderate', @presenter.send(:activity_tier)
    end

    test 'self_report_alignment when aligned' do
      result = @presenter.send(:self_report_alignment)
      assert_equal true, result[:aligned]
      assert_nil result[:note]
    end

    test 'self_report_alignment when not aligned' do
      health_summary = health_summaries(:night_owl)
      presenter = SummaryPresenter.new(health_summary, @preference_profile)
      result = presenter.send(:self_report_alignment)

      assert_equal false, result[:aligned]
      assert_not_nil result[:note]
    end

    test 'self_report_alignment when no preference_profile' do
      presenter = SummaryPresenter.new(@health_summary, nil)
      assert_nil presenter.send(:self_report_alignment)
    end
  end
end
