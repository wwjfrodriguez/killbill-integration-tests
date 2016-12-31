# encoding: utf-8

$LOAD_PATH.unshift File.expand_path('../..', __FILE__)

require 'test_base'

module KillBillIntegrationTests

  class TestShoppingCardTest < Base

    def setup
      setup_base
      upload_catalog('SpyCarAdvanced.xml', false, @user, @options)
      @account = create_account(@user, @options)
      @ext_key_prefix = "#{@account.account_id}-" + rand(1000000).to_s
      # Used for sorting
      @ext_key_postfix = 0
    end

    def teardown
      teardown_base
    end

    def test_multiple_bundles_with_default


      bundle1 = []
      bundle1 << to_base_subscription_input(@account.account_id, get_monotic_inc_bundle_ext_key, 'sports-monthly', nil, nil)
      bundle1 << to_ao_subscription_input(@account.account_id, nil, 'oilslick-monthly', nil, nil)

      bundle2 = []
      bundle2 << to_base_subscription_input(@account.account_id, get_monotic_inc_bundle_ext_key, 'standard-monthly', nil, nil)

      bundle3 = []
      bundle3 << to_base_subscription_input(@account.account_id, get_monotic_inc_bundle_ext_key, 'super-monthly', nil, nil)
      bundle3 << to_ao_subscription_input(@account.account_id, nil, 'gas-monthly', nil, nil)

      KillBillClient::Model::BulkSubscription.create_bulk_subscriptions(to_input(bundle1, bundle2, bundle3), @user, nil, nil, nil, nil, @options)
      wait_for_expected_clause(1, @account, @options, &@proc_account_invoices_nb)

      bundles = @account.bundles(@options)
      assert_equal(3, bundles.size)
      bundles.sort! { |b1, b2| b1.external_key <=> b2.external_key}

      check_bundle(bundle1, bundles[0])
      check_bundle(bundle2, bundles[1])
      check_bundle(bundle3, bundles[2])


      all_invoices = @account.invoices(true, @options)
      assert_equal(1, all_invoices.size)
      sort_invoices!(all_invoices)
      first_invoice = all_invoices[0]
      check_invoice_no_balance(first_invoice, 3.87, 'USD', DEFAULT_KB_INIT_DATE)

      check_invoice_item(find_invoice_item(first_invoice.items, 'oilslick-monthly'), first_invoice.invoice_id, 3.87, 'USD', 'RECURRING', 'oilslick-monthly', 'oilslick-monthly-discount', '2013-08-01', '2013-08-31')
      check_invoice_item(find_invoice_item(first_invoice.items, 'standard-monthly'), first_invoice.invoice_id, 0, 'USD', 'FIXED', 'standard-monthly', 'standard-monthly-trial', '2013-08-01', nil)
      check_invoice_item(find_invoice_item(first_invoice.items, 'super-monthly'), first_invoice.invoice_id, 0, 'USD', 'FIXED', 'super-monthly', 'super-monthly-trial', '2013-08-01', nil)
      check_invoice_item(find_invoice_item(first_invoice.items, 'sports-monthly'), first_invoice.invoice_id, 0, 'USD', 'FIXED', 'sports-monthly', 'sports-monthly-trial', '2013-08-01', nil)
    end


    private


    def to_base_subscription_input(account_id, external_key, plan_name, phase_type, price_overrides)
      subscription = KillBillClient::Model::Subscription.new
      subscription.account_id = account_id
      subscription.product_category = 'BASE'
      subscription.external_key = external_key
      subscription.plan_name = plan_name
      subscription.phase_type = phase_type
      subscription.price_overrides = price_overrides
      subscription
    end


    def to_ao_subscription_input(account_id, bundle_id, plan_name, phase_type, price_overrides)
      subscription = KillBillClient::Model::Subscription.new
      subscription.account_id = account_id
      subscription.product_category = 'ADD_ON'
      subscription.bundle_id = bundle_id
      subscription.plan_name = plan_name
      subscription.phase_type = phase_type
      subscription.price_overrides = price_overrides
      subscription
    end

    def to_input(*bundles)
      bundles.map do |b|
        res = KillBillClient::Model::BulkSubscription.new
        res.base_entitlement_and_add_ons = b
        res
      end
    end

    def get_monotic_inc_bundle_ext_key
      @ext_key_prefix = "#{@account.account_id}-" + rand(1000000).to_s
      @ext_key_postfix += 1
      "#{@ext_key_postfix}-#{@ext_key_prefix}"
    end

    def find_invoice_item(items, plan_name)
      res = items.select { |e| e.plan_name == plan_name}
      assert_equal(1, res.size)
      res[0]
    end

    def check_bundle(exp, actual)
      assert_equal(exp.size, actual.subscriptions.size)
      actual.subscriptions.sort! {|s1, s2| s1.plan_name <=> s2.plan_name }
      exp.sort! {|s1, s2| s1.plan_name <=> s2.plan_name }

      actual.subscriptions.each_with_index do |s, i|
        assert_equal(exp[i].account_id, s.account_id)
        assert_equal(exp[i].product_category, s.product_category)
        assert_equal(exp[i].plan_name, s.plan_name)
      end
    end
  end
end
