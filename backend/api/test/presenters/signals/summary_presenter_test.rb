# frozen_string_literal: true

require 'test_helper'

module Signals
  class SummaryPresenterTest < ActiveSupport::TestCase
    setup do
      @health_summary = health_summaries(:alice_health)
      @user = @health_summary.user
    end

    test 'chronotype_label translation' do
      presenter = SummaryPresenter.new(health_summary: @health_summary, user: @user)
      assert_equal 'Early bird', presenter.as_json[:chronotype_label]
    end

    test 'peak_energy_window formatting' do
      presenter = SummaryPresenter.new(health_summary: @health_summary, user: @user)
      assert_equal '21:00–23:00', presenter.as_json[:peak_energy_window]
    end

    test 'routine_stability_tier calculation' do
      presenter = SummaryPresenter.new(health_summary: @health_summary, user: @user)
      assert_equal 'high', presenter.as_json[:routine_stability_tier]
    end

    test 'activity_tier translation' do
      presenter = SummaryPresenter.new(health_summary: @health_summary, user: @user)
      assert_equal 'moderate', presenter.as_json[:activity_tier]
    end

    test 'self_report_alignment when aligned' do
      @health_summary.update!(chronotype: 'early_bird')
      @user.preference_profile.update!(self_chronotype: 'early_bird')

      presenter = SummaryPresenter.new(health_summary: @health_summary, user: @user)
      assert_equal true, presenter.as_json[:self_report_alignment][:aligned]
    end

    test 'self_report_alignment when not aligned' do
      @health_summary.update!(chronotype: 'night_owl')
      @user.preference_profile.update!(self_chronotype: 'early_bird')

      presenter = SummaryPresenter.new(health_summary: @health_summary, user: @user)
      assert_equal false, presenter.as_json[:self_report_alignment][:aligned]
      assert_includes presenter.as_json[:self_report_alignment][:note], 'Night owl'
    end

    test 'self_report_alignment is nil when no preference profile' do
      user_without_prefs = users(:bob)
      presenter = SummaryPresenter.new(health_summary: @health_summary, user: user_without_prefs)
      assert_nil presenter.as_json[:self_report_alignment]
    end

    test 'peak_energy_window is nil when times are nil' do
      @health_summary.update!(peak_energy_start_local: nil, peak_energy_end_local: nil)
      presenter = SummaryPresenter.new(health_summary: @health_summary, user: @user)
      assert_nil presenter.as_json[:peak_energy_window]
    end
  end
end
