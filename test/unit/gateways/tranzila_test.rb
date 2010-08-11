require 'helper'
require 'rubygems'
require 'ruby-debug'

class TranzilaTest < Test::Unit::TestCase
  def setup
    @gateway = TranzilaGateway.new(:supplier => 'test3', :currency => '1')

    @credit_card = credit_card('4444333322221111')
    @amount = 100.00

    @options = {
      :cred_type => '1',
      :myid => '306122847',
      :ConfirmationCode => '0000000',
      :index => '11'
    }
  end

  def test_successful(successful_response, action)
    @gateway.expects(:ssl_post).returns(successful_response)

    assert response = @gateway.send(action, @amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_success response

    assert_equal '000', response.params['Response']
    assert response.test?
  end

  def test_unsuccessful(failed_response, action, opts = {})
    @gateway.expects(:ssl_post).returns(failed_response)

    assert response = @gateway.send(action, @amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  def test_successful_purchase
    test_successful(successful_purchase_response, :purchase)
  end

  def test_unsuccessful_purchase
    test_unsuccessful(failed_purchase_response, :purchase)
  end

  def test_successful_authorize
    test_successful(successful_authorize_response, :authorize)
  end

  def test_unsuccessful_authorize
    test_unsuccessful(failed_authorize_response, :authorize)
  end

  def test_successful_capture
    test_successful(successful_capture_response, :capture)
  end

  def test_unsuccessful_capture
    test_unsuccessful(failed_capture_response, :capture)
  end

  def test_successful_refund
    test_successful(successful_refund_response, :refund)
  end

  def test_unsuccessful_capture
    test_unsuccessful(failed_refund_response, :refund)
  end

  private

  def failed_refund_response
    "<html><head><META NAME=\"ROBOTS\" CONTENT=\"NOINDEX, NOFOLLOW\"></head><body>\n<center><h1>Tranzila</h1><br>\nAn error ocurred with the following message:<br>\n<h3><b><font color=red> Transaction can't be credited </font></b><br></h3>\nPlease use the BACK button in your browser.<br>\n</center></body></html>"
  end

  def successful_refund_response
    "Response=000&mycvv=333&expmonth=09&task=Doforce&myid=306122847&currency=1&cred_type=1&ccno=4444333322221111&expyear=15&authnr=0000000&supplier=test3&expdate=0915&tranmode=F&sum=1.00&ConfirmationCode=0000000&index=112&Tempref=03870001\n\n"
  end

  def successful_capture_response
    "Response=000&mycvv=333&expmonth=09&task=Doforce&myid=306122847&currency=1&cred_type=1&ccno=4444333322221111&expyear=15&authnr=0000000&supplier=test3&expdate=0915&tranmode=F&sum=1.00&ConfirmationCode=0000000&index=112&Tempref=03870001\n\n"
  end

  def failed_capture_response
    "Response=004&mycvv=333&expmonth=09&task=Doforce&myid=306122847&currency=1&cred_type=1&ccno=4444333322221111&expyear=15&authnr=0000000&supplier=test3&expdate=0915&tranmode=F&sum=1.00&ConfirmationCode=0000000&index=112&Tempref=03870001\n\n"
  end

  #
  def successful_authorize_response
    "Response=000&mycvv=333&expmonth=09&task=Doverify&myid=306122847&currency=1&cred_type=1&ccno=4444333322221111&expyear=15&supplier=test3&expdate=0915&tranmode=V&sum=1.00&ConfirmationCode=0000000&index=110&Tempref=03480001\n\n"
  end

  def failed_authorize_response
    "Response=004&mycvv=333&expmonth=09&task=Doverify&myid=306122847&currency=1&cred_type=1&ccno=4444333322221111&expyear=15&supplier=test3&expdate=0915&tranmode=V&sum=1.00&ConfirmationCode=0000000&index=110&Tempref=03480001\n\n"
  end

  # raw failed response from gateway here
  def failed_purchase_response
    "Response=004&fpay=&mycvv=123&expmonth=9&spay=&myid=306122847&currency=1&ccno=4444333322221111&cred_type=1&expyear=15&supplier=test3&npay=&id=6&expdate=915&sum=100.0&ConfirmationCode=0000000&index=11&Tempref=01130001&CVVstatus=3&Responsesource=2\n\n"
  end

  # raw successful response from gateway here
  def successful_purchase_response
    "Response=000&ccno=4444333322221111&currency=1&cred_type=1&mycvv=123&expyear=15&supplier=test3&expmonth=09&myid=306122847&expdate=0915&sum=1.00&ConfirmationCode=0000000&index=88&Tempref=01300001&CVVstatus=3&Responsesource=0\n\n"
  end

end
