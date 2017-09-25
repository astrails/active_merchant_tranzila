require 'active_merchant'
module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # This class implements the Tranzila (http://www.tranzila.com) Israeli payment gateway.
    # Implemented by http://www.astrails.com
    #
    # == Supported transaction types by TranzilaGateway:
    # * - Purchase
    # * - Refund
    # * - Authorize
    # * - Capture
    #
    # == Notes
    # * Recurring billing is not yet implemented.
    # * Adding of order products information is not implemented.
    # * There is no test URL, use tranzila test account
    #
    #  Example purchase:
    #
    #   gateway = ActiveMerchant::Billing::TranzilaGateway.new(:supplier => 'YOUR_SUPPLIER_ID', :currency => 1)
    #   creditcard = ActiveMerchant::Billing::CreditCard.new(
    #     :number => '4444333322221111',
    #     :month => '09',
    #     :year => '2015',
    #     :verification_value => '333'
    #   )
    #
    #   response = gateway.purchase(
    #     100, # cents here
    #     creditcard,
    #     { :cred_type => '1', :myid => '306122847' }
    #   )
    #
    #   response.inspect
    class TranzilaGateway < Gateway

      SHEKEL_DOLLAR_URL = 'https://secure5.tranzila.com/cgi-bin/tranzila31.cgi'
      MULTICURRENCY_URL = 'https://secure5.tranzila.com/cgi-bin/tranzila36a.cgi'

      RESPONSE_MESSAGES = {
        '000' => 'Transaction approved',
        '001' => 'Blocked confiscate card.',
        '002' => 'Stolen confiscate card.',
        '003' => 'Contact credit company.',
        '004' => 'Refusal.',
        '005'	=> 'Forged. confiscate card.',
        '006' => 'Identity Number of CVV incorrect.',
        '007' => 'Must contact Credit Card Company',
        '008' => 'Fault in building of access key to blocked cards file.',
        '009' => 'Contact unsuccessful.',
        '010' => 'Program ceased by user instruction (ESC).',
        '011' => 'No confirmation for the ISO currency clearing.',
        '012' => 'No confirmation for the ISO currency type.',
        '013' => 'No confirmation for charge/discharge transaction.',
        '014' => 'Unsupported card',
        '015' => 'Number Entered and Magnetic Strip do not match',
        '017' => 'Last 4 digets not entered',
        '019' => 'Record in INT_IN shorter than 16 characters.',
        '020' => 'Input file (INT_IN) does not exist.',
        '021' => 'Blocked cards file (NEG) non-existent or has not been updated - execute transmission or request authorization for each transaction.',
        '022' => 'One of the parameter files or vectors do not exist.',
        '023' => 'Date file (DATA) does not exist.',
        '024' => 'Format file (START) does not exist.',
        '025' => 'Difference in days in input of blocked cards is too large - execute transmission or request authorization for each transaction.',
        '026' => 'Difference in generations in input of blocked cards is too large - execute transmission or request authorization for each transaction.',
        '027' => 'Where the magnetic strip is not completely entered',
        '028' => 'Central terminal number not entered into terminal defined for work as main supplier.',
        '029' => 'Beneficiary number not entered into terminal defined as main beneficiary.',
        '030' => 'Terminal not updated as main supplier/beneficiary and supplier/beneficiary number entered.',
        '031' => 'Terminal updated as main supplier and beneficiary number entered',
        '032' => 'Old transactions - carry out transmission or request authorization for each transaction.',
        '033' => 'Defective card',
        '034' => 'Card not permitted for this terminal or no authorization for this type of transaction.',
        '035' => 'Card not permitted for transaction or type of credit.',
        '036' => 'Expired.',
        '037' => 'Error in instalments - Amount of transaction needs to be equal to the first instalment + (fixed instalments times no. of instalments)',
        '038' => 'Cannot execute transaction in excess of credit card ceiling for immediate debit.',
        '039' => 'Control number incorrect.',
        '040' => 'Terminal defined as main beneficiary and supplier number entered.',
        '041' => 'Exceeds ceiling where input file contains J1 or J2 or J3 (contact prohibited).',
        '042' => 'Card blocked for supplier where input file contains J1 or J2 or J3 (contact prohibited).',
        '043' => 'Random where input file contains J1 (contact prohibited).',
        '044' => 'Terminal prohibited from requesting authorization without transaction (J5)',
        '045' => 'Terminal prohibited for supplier-initiated authorization request (J6)',
        '046' => 'Terminal must request authorization where input file contains J1 or J2 or J3 (contact prohibited).',
        '047' => 'Secret code must be entered where input file contains J1 or J2 or J3 (contact prohibited).',
        '051' => ' Vehicle number defective.',
        '052' => 'Distance meter not entered.',
        '053' => 'Terminal not defined as gas station. (petrol card passed or incorrect transaction code).',
        '057' => 'Identity Number Not Entered',
        '058' => 'CVV2 Not Entered',
        '059' => 'Identiy Number and CVV2 Not Entered',
        '060' => 'ABS attachment not found at start of input data in memory.',
        '061' => 'Card number not found or found twice',
        '062' => 'Incorrect transaction type',
        '063' => 'Incorrect transaction code.',
        '064' => 'Type of credit incorrect.',
        '065' => 'Incorrect currency.',
        '066' => 'First instalment and/or fixed payment exists for non-instalments type of credit.',
        '067' => 'Number of instalments exists for type of credit not requiring this.',
        '068' => 'Linkage to dollar or index not possible for credit other than instalments.',
        '069' => 'Length of magnetic strip too short.',
        '070' => 'PIN terminal not defined',
        '071' => 'PIN must be enetered',
        '072' => 'Secret code not entered.',
        '073' => 'Incorrect secret code.',
        '074' => 'Incorrect secret code - last try.',
        '079' => 'Currency is not listed in vector 59.',
        '080' => '"Club code" entered for unsuitable credit type',
        '090' => 'Transaction cancelling is not allowed for this card.',
        '091' => 'Transaction cancelling is not allowed for this card.',
        '092' => 'Transaction cancelling is not allowed for this card.',
        '099' => 'Cannot read/write/open TRAN file.',
        '100' => 'No equipment for inputting secret code.',
        '101' => 'No authorization from credit company for work.',
        '107' => 'Transaction amount too large - split into a number of transactions.',
        '108' => 'Terminal not authorized to execute forced actions.',
        '109' => 'Terminal not authorized for card with service code 587.',
        '110' => 'Terminal not authorized for immediate debit card.',
        '111' => 'Terminal not authorized for instalments transaction.',
        '112' => 'Terminal not authorized for telephone/signature only instalments transaction.',
        '113' => 'Terminal not authorized for telephone transaction.',
        '114' => 'Terminal not authorized for "signature only" transaction.',
        '115' => 'Terminal not authorized for dollar transaction.',
        '116' => 'Terminal not authorized for club transaction.',
        '117' => 'Terminal not authorized for stars/points/miles transaction.',
        '118' => 'Terminal not authorized for Isracredit credit.',
        '119' => 'Terminal not authorized for Amex Credit credit.',
        '120' => 'Terminal not authorized for dollar linkage.',
        '121' => 'Terminal not authorized for index linkage.',
        '122' => 'Terminal not authorized for index linkage with foreign cards.',
        '123' => 'Terminal not authorized for stars/points/miles transaction for this type of credit.',
        '124' => 'Terminal not authorized for Isracredit payments.',
        '125' => 'Terminal not authorized for Amex payments.',
        '126' => 'Terminal not authorized for this club code.',
        '127' => 'Terminal not authorized for immediate debit transaction except for immediate debit cards.',
        '128' => 'Terminal not authorized to accept Visa card staring with 3.',
        '129' => 'Terminal not authorized to execute credit transaction above the ceiling.',
        '130' => 'Card not permitted for execution of club transaction.',
        '131' => 'Card not permitted for execution stars/points/miles transaction.',
        '132' => 'Card not permitted for execution of dollar transactions (regular or telephone).',
        '133' => 'Card not valid according Isracard list of valid cards.',
        '134' => 'Defective card according to system definitions (Isracard VECTOR1) - no. of figures on card - error.',
        '135' => 'Card not permitted to execute dollar transactions according to system definition (Isracard VECTOR1).',
        '136' => 'Card belongs to group not permitted to execute transactions according to system definition (Visa VECTOR 20).',
        '137' => 'Card prefix (7 figures) invalid according to system definition (Diners VECTOR21)',
        '138' => 'Card not permitted to carry out instalments transaction according to Isracard list of valid cards.',
        '139' => 'Number of instalments too large according to Isracard list of valid cards.',
        '140' => 'Visa and Diners cards not permitted for club instalments transactions.',
        '141' => 'Series of cards not valid according to system definition (Isracard VECTOR5).',
        '142' => 'Invalid service code according to system definition (Isracard VECTOR6).',
        '143' => 'Card prefix (2 figures) invalid according to system definition (Isracard VECTOR7).',
        '144' => 'Invalid service code according to system definition (Visa VECTOR12).',
        '145' => 'Invalid service code according to system definition (Visa VECTOR13).',
        '146' => 'Immediate debit card prohibited for execution of credit transaction.',
        '147' => 'Card not permitted to execute instalments transaction according to Leumicard vector no. 31.',
        '148' => 'Card not permitted for telephone and signature only transaction according to Leumicard vector no. 31',
        '149' => 'Card not permitted for telephone transaction according to Leumicard vector no. 31',
        '150' => 'Credit not approved for immediate debit cards.',
        '151' => 'Credit not approved for foreign cards.',
        '152' => 'Club code incorrect.',
        '153' => 'Card not permitted to execute flexible credit transactions (Adif/30+) according to system definition (Diners VECTOR21).',
        '154' => 'Card not permitted to execute immediate debit transactions according to system definition (Diners VECTOR21).',
        '155' => 'Amount of payment for credit transaction too small.',
        '156' => 'Incorrect number of instalments for credit transaction',
        '157' => '0 ceiling for this type of card for regular credit or Credit transaction.',
        '158' => '0 ceiling for this type of card for immediate debit credit transaction',
        '159' => '0 ceiling for this type of card for immediate debit in dollars.',
        '160' => '0 ceiling for this type of card for telephone transaction.',
        '161' => '0 ceiling for this type of card for credit transaction.',
        '162' => '0 ceiling for this type of card for instalments transaction.',
        '163' => 'American Express card issued abroad not permitted for instalments transaction.',
        '164' => 'JCB cards permitted to carry out regular credit transactions.',
        '165' => 'Amount in stars/points/miles larger than transaction amount.',
        '166' => 'Club card not in terminal range.',
        '167' => 'Stars/points/miles transaction cannot be executed.',
        '168' => 'Dollar transaction cannot be executed for this type of card.',
        '169' => 'Credit transaction cannot be executed with other than regular credit.',
        '170' => 'Amount of discount on stars/points/miles greater than permitted.',
        '171' => 'Forced transaction cannot be executed with credit/immediate debut card.',
        '172' => 'Previous transaction cannot be cancelled (credit transaction or card number not identical).',
        '173' => 'Double transaction.',
        '174' => 'Terminal not permitted for index linkage for this type of credit.',
        '175' => 'Terminal not permitted for dollar linkage for this type of credit.',
        '176' => 'Card invalid according to system definition (Isracard VECTOR1)',
        '177' => 'Cannot execute "Self-Service" transaction at gas stations except at "Self-Service at gas stations".',
        '178' => 'Credit transaction forbidden with stars/points/miles.',
        '179' => 'Dollar credit transaction forbidden on tourist card.',
        '180' => 'Club Card can not preform Telephone Transactions',
        '200' => 'Application error.',
        '700' => 'Approved TEST Masav transaction',
        '701' => 'Invalid Bank Number',
        '702' => 'Invalid Branch Number',
        '703' => 'Invalid Account Number',
        '704' => 'Incorrect Bank/Branch/Account Combination',
        '705' => 'Application Error',
        '706' => 'Supplier directory does not exist',
        '707' => 'Supplier configuration does not exist',
        '708' => 'Charge amount zero or negative',
        '709' => 'Invalid configuration file',
        '710' => 'Invalid date format',
        '711' => 'DB Error',
        '712' => 'Required parameter is missing',
        '800' => 'Transaction Canceled',
        '900' => '3D Secure Failed',
        '903' => 'Fraud suspected',
        '951' => 'Protocol Error',
        '952' => 'Payment not completed',
        '954' => 'Payment Failed',
        '955' => 'Payment status error',
        '959' => 'Payment completed unsuccessfully',
      }

      # The homepage URL of the gateway
      self.homepage_url = 'http://tranzila.com'

      # The name of the gateway
      self.display_name = 'Tranzila'

      # Creates a new TranzilaGateway
      #
      # The gateway requires that a valid supplier name be passed
      # in the +options+ hash.
      #
      # ==== Options
      #
      # * <tt>options</tt>
      #   * <tt>:currency</tt> - Possible values:
      #     1 - Shekels
      #     2 - US Dollars
      #     3 - GBP
      #     4 - Shekel transaction with installments linked to the US Dollar
      #     5 - HKD
      #     6 - JPY
      #     7 - Euro
      #     8 - Index-linked installments transaction
      #   * <tt>:supplier</tt> - The Tranzila account name.
      def initialize(options = {})
        requires!(options, :supplier, :currency)
        @options = options
        super
      end

      # Authorize and immediately capture funds from a credit card.
      #
      # ==== Parameters
      #
      # * <tt>money</tt> - The amount to be authorized and captured as an Integer value in cents or agorot.
      # * <tt>creditcard</tt> - The CreditCard details for the transaction.
      # * <tt>options</tt>
      #   * <tt>:cred_type</tt> - Possible values:
      #     1- Regular Credit
      #     2- Isracredit, Visa Adif/30+, Amex Credit, Diners Adif/30+
      #     3- Immediate Debit
      #     4- Club Credit
      #     5- Leumi Special
      #     6- Visa credit, Diners credit, Isra36, Amex 36
      #     8- Installments
      #     9- Club installments
      #   * <tt>:myid</tt> - Israeli ID number (9 digits)
      def purchase(cents, creditcard, options = {})
        requires!(options, :cred_type, :myid)
        commit('sale', cents, creditcard, options)
      end

      # Authorize
      #
      # ==== Parameters
      #
      # * <tt>money</tt> - The amount to be authorized as an Integer value in cents or agorot.
      # * <tt>creditcard</tt> - The CreditCard details for the transaction.
      # * <tt>options</tt>
      #   * <tt>:cred_type</tt> - Possible values:
      #     1- Regular Credit
      #     2- Isracredit, Visa Adif/30+, Amex Credit, Diners Adif/30+
      #     3- Immediate Debit
      #     4- Club Credit
      #     5- Leumi Special
      #     6- Visa credit, Diners credit, Isra36, Amex 36
      #     8- Installments
      #     9- Club installments
      #   * <tt>:myid</tt> - Israeli ID number (9 digits)
      def authorize(money, creditcard, options = {})
        requires!(options, :cred_type, :myid)
        commit('authorize', money, creditcard, options)
      end

      # Capture funds
      #
      # ==== Parameters
      #
      # * <tt>money</tt> - The amount to be authorized as an Integer value in cents or agorot.
      # * <tt>creditcard</tt> - The CreditCard details for the transaction.
      # * <tt>options</tt>
      #   * <tt>:ConfirmationCode</tt> - The ConfirmationCode parameter got from the from the Purchase or Authorize request
      #   * <tt>:cred_type</tt> - Possible values:
      #     1- Regular Credit
      #     2- Isracredit, Visa Adif/30+, Amex Credit, Diners Adif/30+
      #     3- Immediate Debit
      #     4- Club Credit
      #     5- Leumi Special
      #     6- Visa credit, Diners credit, Isra36, Amex 36
      #     8- Installments
      #     9- Club installments
      #   * <tt>:myid</tt> - Israeli ID number (9 digits)
      def capture(money, creditcard, options = {})
        requires!(options, :cred_type, :myid, :ConfirmationCode)
        commit('capture', money, creditcard, options)
      end

      # Refund (credit) the transaction
      #
      # ==== Parameters
      #
      # * <tt>money</tt> - The amount to be authorized as an Integer value in cents or agorot.
      # * <tt>creditcard</tt> - The CreditCard details for the transaction.
      # * <tt>options</tt>
      #   * <tt>:index</tt> - Tranzila transaction index number. Should be reseived from the Purchase or Authorize request
      #   * <tt>:ConfirmationCode</tt> - The ConfirmationCode parameter got from the from the Purchase or Authorize request
      #   * <tt>:cred_type</tt> - Possible values:
      #     1- Regular Credit
      #     2- Isracredit, Visa Adif/30+, Amex Credit, Diners Adif/30+
      #     3- Immediate Debit
      #     4- Club Credit
      #     5- Leumi Special
      #     6- Visa credit, Diners credit, Isra36, Amex 36
      #     8- Installments
      #     9- Club installments
      #   * <tt>:myid</tt> - Israeli ID number (9 digits)
      def refund(money, creditcard, options = {})
        requires!(options, :index, :ConfirmationCode)
        commit('refund', money, creditcard, options)
      end

      private

      def parse(body)
        response_to_h(body.try(:chop!).try(:chop!))
      end

      def response_to_h(body)
        parts = body.split(/&|=/)
        Hash[*parts]
      end

      def commit(action, money, creditcard, options = {})
        response = parse(ssl_post(multicurrency? ? MULTICURRENCY_URL : SHEKEL_DOLLAR_URL, post_data(action, money, creditcard, options)))

        Response.new(successful?(response), message_from(response), response,
          :test => test?,
          :authorization => response['ConfirmationCode'],
          :cvv_result => response['CVVstatus']
        )
      end

      def multicurrency?
        ![1, 2, 4].include?(@options[:currency])
      end

      def successful?(response)
        response['Response'] == "000"
      end

      def message_from(response)
        RESPONSE_MESSAGES.fetch(response.fetch('Response', nil), nil)
      end

      def post_data(action, money, creditcard, options = {})
        return purchase_parameters(money, creditcard, options) if action == 'sale'
        return refund_parametes(money, creditcard, options) if action == 'refund'
        return authorize_parameters(money, creditcard, options) if action == 'authorize'
        return capture_parameters(money, creditcard, options) if action == 'capture'
      end

      def capture_parameters(money, creditcard, options = {})
        to_query_s({
          :task => "Doforce",
          :tranmode => 'F',
          :authnr => options[:ConfirmationCode]
        }.merge(default_parameters_hash(money, creditcard, options)))
      end

      def authorize_parameters(money, creditcard, options = {})
        to_query_s({
          :task => 'Doverify',
          :tranmode => 'V',
        }.merge(default_parameters_hash(money, creditcard, options)))
      end

      def refund_parametes(money, creditcard, options = {})
        to_query_s({
           :tranmode => "C#{options[:index]}",
           :authnr => options[:ConfirmationCode],
        }.merge(default_parameters_hash(money, creditcard, options)))
      end

      def purchase_parameters(money, creditcard, options = {})
        to_query_s(default_parameters_hash(money, creditcard, options))
      end

      def default_parameters_hash(money, creditcard, options = {})
        default_params = {
          :sum => amount(money),
          :ccno => creditcard.number,
          :expyear => creditcard.year.to_s[-2, 2],
          :expmonth => creditcard.month,
          :expdate => "#{creditcard.month}#{creditcard.year.to_s[-2, 2]}",
          :mycvv => creditcard.verification_value,

          #Possible Values:
          #1- Regular Credit
          #2- Isracredit, Visa Adif/30+,Amex Credit, Diners Adif/30+
          #3- Immediate Debit
          #4- Club Credit
          #5- Leumi Special
          #6- Visa credit, Diners credit, Isra36, Amex 36
          #8- Installments
          #9- Club installments
          :cred_type => options[:cred_type],
          :currency => @options[:currency],
          :myid => options[:myid],
          #transaction with monthly installments not supported yet
          #:fpay => options[:myid],
          #:spay => options[:spay],
          #:npay => options[:npay],

          #tranzila registered supplier (test3)
          :supplier => @options[:supplier]
        }

        [:email, :company, :contact].each do |param|
          default_params[param] = options[param].encode("windows-1255") if options.key?(param)
        end

        default_params
      end

      def to_query_s(hash)
        hash.map{|k,v| "#{k}=#{v}"}.join("&")
      end
    end
  end
end
