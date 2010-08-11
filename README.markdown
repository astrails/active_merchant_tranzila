# ActiveMerchantTranzila

[Tranzila](http://tranzila.com) gateway support for [ActiveMerchant](http://www.activemerchant.org/).

## Installation

### Requirements

First you need the ActiveMerchant gem / rails-plugin installed. More info about
ActiveMerchant installation can be found in [ActiveMerchant documentation](http://activemerchant.rubyforge.org/).

### As a Rails plugin

To install ActiveMerchantTranzila in your rails app you can just do:

    ./script/plugin install git://github.com/astrails/active_merchant_tranzila

### As a gem

To install ActiveMerchantTranzila in your rails app you can just do:

    config.gem 'active_merchant_tranzila'

## Configuration

Signup on [Tranzila site](http://tranzila.com) to obtain your own 'supplier' id.

## Example Usage

Once you've configured the Ogone settings you need to set up a leaving page with in your view:

    gateway = ActiveMerchant::Billing::TranzilaGateway.new(:supplier => 'YOUR_SUPPLIER_ID', :currency => 1)
    creditcard = ActiveMerchant::Billing::CreditCard.new(
      :number => '4444333322221111',
      :month => '09',
      :year => '2015',
      :verification_value => '333'
    )

    response = gateway.purchase(
      100, # cents here
      creditcard,
      { :cred_type => '1', :myid => '306122847' }
    )

    response.inspect

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Astrails Ltd. See LICENSE for details.
