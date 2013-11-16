$LOAD_PATH.unshift File.expand_path('../..', __FILE__)

require 'test_base'

module KillBillIntegrationSeed

  class TestAccountTimezone < KillBillIntegrationTests::Base

    def setup
      @user = "admin"
      @init_clock = '2013-02-08T01:00:00.000Z'
      setup_base(@user, false, @init_clock)

    end

    def teardown
      teardown_base
    end

=begin
Create a few accounts with different currencies, locale, timezone:
- Check BCD is 10 for all except John Silver for which this is 9   (explain why 9 and 10)
- Check currency is correctly represented
- Check invoice template works for various locale -> TODO  (missing invoice template and catalog translation)
- Explain failed payments
- Explain why subscription start at different dates (similar to BCD)
=end

    def test_seed_timezone

      data = {}
      data[:name] = 'Brian King'
      data[:external_key] = 'brianking'
      data[:email] = 'brianking@kb.com'
      data[:currency] = 'GBP'
      data[:time_zone] = 'Europe/London'
      data[:address1] = '5 Downing street'
      data[:address2] = nil
      data[:postal_code] = 'E11 8QS'
      data[:company] = nil
      data[:city] = 'London'
      data[:state] = 'Greater London'
      data[:country] = 'England'
      data[:locale] = 'en_GB'
      @brianking = create_account_with_data(@user, data, @options)
      add_payment_method(@brianking.account_id, '__EXTERNAL_PAYMENT__', true, @user, @options)

      data = {}
      data[:name] = 'John Silver'
      data[:external_key] = 'johnsilver'
      data[:email] = 'johnsilver@kb.com'
      data[:currency] = 'USD'
      data[:time_zone] = 'Pacific/Samoa'
      data[:address1] = '1234, Alabama street'
      data[:address2] = nil
      data[:postal_code] = '66799'
      data[:company] = nil
      data[:city] = 'Pago Pago'
      data[:state] = 'Pago Pago'
      data[:country] = 'USA'
      data[:locale] = 'en_US'
      @johnsilver = create_account_with_data(@user, data, @options)
      add_payment_method(@johnsilver.account_id, '__EXTERNAL_PAYMENT__', true, @user, @options)


      data = {}
      data[:name] = 'Paul Dupond'
      data[:external_key] = 'pauldupond'
      data[:email] = 'pauldupond@kb.com'
      data[:currency] = 'EUR'
      data[:time_zone] = 'Europe/Paris'
      data[:address1] = '5, rue des ecoles'
      data[:address2] = nil
      data[:postal_code] = '25000'
      data[:company] = nil
      data[:city] = 'Besancon'
      data[:state] = 'Franche Comte'
      data[:country] = 'France'
      data[:locale] = 'fr_FR'
      @pauldupond = create_account_with_data(@user, data, @options)
      add_payment_method(@pauldupond.account_id, '__EXTERNAL_PAYMENT__', true, @user, @options)

      data = {}
      data[:name] = 'Yokuri Matsumoto'
      data[:external_key] = 'yokurimatsumoto'
      data[:email] = 'yokurimatsumoto@kb.com'
      data[:currency] = 'JPY'
      data[:time_zone] = 'Asia/Tokyo'
      data[:address1] = 'block 5'
      data[:address2] = nil
      data[:postal_code] = '25000'
      data[:company] = nil
      data[:city] = 'Tokyo'
      data[:state] = 'Kanto Region'
      data[:country] = 'Japan'
      data[:locale] = 'ja_JP'
      @yokurimatsumoto = create_account_with_data(@user, data, @options)
      add_payment_method(@yokurimatsumoto.account_id, '__EXTERNAL_PAYMENT__', true, @user, @options)


      pbs = []
      pbs << create_entitlement_base(@brianking.account_id, 'Sports', 'MONTHLY', 'DEFAULT', @user, @options)

      pbs << create_entitlement_base(@johnsilver.account_id, 'Sports', 'MONTHLY', 'DEFAULT', @user, @options)

      pbs << create_entitlement_base(@pauldupond.account_id, 'Sports', 'MONTHLY', 'DEFAULT', @user, @options)

      pbs << create_entitlement_base(@yokurimatsumoto.account_id, 'Sports', 'MONTHLY', 'DEFAULT', @user, @options)

      kb_clock_add_days(31, nil, @options)

      # Cancel all plans so we stop invoicing those accounts in the future
      bps.each do |bp|
        bp.cancel(@user, nil, nil, nil, 'IMMEDIATE', 'END_OF_TERM', nil, @options)
      end
    end

  end
end