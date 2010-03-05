require 'digest/sha1'

module BlueLightSpecial
  module User
    
    Admin = 'admin'
    
    # Hook for all BlueLightSpecial::User modules.
    #
    # If you need to override parts of BlueLightSpecial::User,
    # extend and include à la carte.
    #
    # @example
    #   extend ClassMethods
    #   include InstanceMethods
    #   include AttrAccessor
    #   include Callbacks
    #
    # @see ClassMethods
    # @see InstanceMethods
    # @see AttrAccessible
    # @see AttrAccessor
    # @see Validations
    # @see Callbacks
    def self.included(model)
      model.extend(ClassMethods)

      model.send(:include, InstanceMethods)
      model.send(:include, AttrAccessor)
      model.send(:include, Validations)
      model.send(:include, Callbacks)
    end

    module AttrAccessor
      # Hook for attr_accessor virtual attributes.
      #
      # :password, :password_confirmation
      def self.included(model)
        model.class_eval do
          attr_accessor :password, :password_confirmation
        end
      end
    end

    module Validations
      # Hook for validations.
      #
      # :email must be present, unique, formatted
      #
      # If password is required,
      # :password must be present, confirmed
      def self.included(model)
        model.class_eval do
          validates_presence_of     :email, :unless => :email_optional?
          validates_uniqueness_of   :email, :case_sensitive => false, :allow_blank => true
          validates_format_of       :email, :with => %r{.+@.+\..+}, :allow_blank => true

          validates_presence_of     :password, :unless => :password_optional?
          validates_confirmation_of :password, :unless => :password_optional?
        end
      end
    end

    module Callbacks
      # Hook for callbacks.
      #
      # salt, token, password encryption are handled before_save.
      def self.included(model)
        model.class_eval do
          before_save   :initialize_salt,
                        :encrypt_password
          before_create :generate_remember_token
          after_create  :send_welcome_email
        end
      end
    end

    module InstanceMethods
      # Am I authenticated with given password?
      #
      # @param [String] plain-text password
      # @return [true, false]
      # @example
      #   user.authenticated?('password')
      def authenticated?(password)
        encrypted_password == encrypt(password)
      end

      # Set the remember token.
      #
      # @deprecated Use {#reset_remember_token!} instead
      def remember_me!
        warn "[DEPRECATION] remember_me!: use reset_remember_token! instead"
        reset_remember_token!
      end

      # Reset the remember token.
      #
      # @example
      #   user.reset_remember_token!
      def reset_remember_token!
        generate_remember_token
        save(false)
      end

      # Mark my account as forgotten password.
      #
      # @example
      #   user.forgot_password!
      def forgot_password!
        generate_password_reset_token
        save(false)
      end

      # Update my password.
      #
      # @param [String, String] password and password confirmation
      # @return [true, false] password was updated or not
      # @example
      #   user.update_password('new-password', 'new-password')
      def update_password(new_password, new_password_confirmation)
        self.password              = new_password
        self.password_confirmation = new_password_confirmation
        if valid?
          self.password_reset_token = nil
        end
        save
      end
      
      def facebook_user?
        !self.facebook_uid.blank?
      end
      
      ##
      # Returns +true+ if the user is an admin.
      # 
      def admin?
        self.role == Admin
      end
      
      protected

      def generate_hash(string)
        Digest::SHA1.hexdigest(string)
      end

      def initialize_salt
        if new_record?
          self.salt = generate_hash("--#{Time.now.utc}--#{password}--#{rand}--")
        end
      end

      def encrypt_password
        return if password.blank?
        self.encrypted_password = encrypt(password)
      end

      def encrypt(string)
        generate_hash("--#{salt}--#{string}--")
      end
      
      def generate_password_reset_token
        self.password_reset_token = encrypt("--#{Time.now.utc}--#{password}--#{rand}--")
      end
      
      def generate_remember_token
        self.remember_token = encrypt("--#{Time.now.utc}--#{encrypted_password}--#{id}--#{rand}--")
      end

      # Always false. Override to allow other forms of authentication
      # (username, facebook, etc).
      # @return [Boolean] true if the email field be left blank for this user
      def email_optional?
        false
      end

      # True if the password has been set and the password is not being
      # updated. Override to allow other forms of # authentication (username,
      # facebook, etc).
      # @return [Boolean] true if the password field can be left blank for this user
      def password_optional?
        encrypted_password.present? && password.blank?
      end

      def password_required?
        # warn "[DEPRECATION] password_required?: use !password_optional? instead"
        !password_optional?
      end
      
      def send_welcome_email
        Delayed::Job.enqueue DeliverWelcomeJob.new(self.id)
      end
      
    end

    module ClassMethods
      # Authenticate with email and password.
      #
      # @param [String, String] email and password
      # @return [User, nil] authenticated user or nil
      # @example
      #   User.authenticate("email@example.com", "password")
      def authenticate(email, password)
        return nil  unless user = find_by_email(email)
        return user if     user.authenticated?(password)
      end
      
      def find_facebook_user(facebook_user)
        user = ::User.find_by_facebook_uid(facebook_user.uid) || ::User.new
        user.tap do |user|
          user.facebook_uid     = facebook_user.uid
          user.email            = facebook_user.email
          user.save
        end
      end
    end

  end
end
