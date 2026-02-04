# This file loads BEFORE omniauth.rb (alphabetically)
# It patches OpenSSL to disable CRL checking in development

if Rails.env.development? || Rails.env.test?
  require "openssl"

  # Patch OpenSSL::X509::Store to not check CRL
  module OpenSSL
    module X509
      class Store
        alias_method :original_set_default_paths, :set_default_paths

        def set_default_paths
          original_set_default_paths
          self.flags = OpenSSL::X509::V_FLAG_CRL_CHECK_ALL & ~OpenSSL::X509::V_FLAG_CRL_CHECK
        end
      end
    end
  end

  puts "✓ OpenSSL CRL checking disabled for development"
end
