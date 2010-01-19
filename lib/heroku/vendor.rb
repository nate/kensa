require 'yajl'

module Heroku

  module Vendor

    class Manifest

      class CheckFailure < StandardError ; end

      def initialize(man)
        @man = man
      end

      def check!

        data = if @man.is_a? Hash
          @man
        else
          Yajl::Parser.parse(@man)
        end


        desc "`api`" do

          check "must exist" do
            data.has_key?("api")
          end

          check "must be a hash" do
            data["api"].is_a?(Hash)
          end

        end


        desc "`plans`" do

          check "must exist" do
            data.has_key?("plans")
          end

          check "must be an array" do
            data["plans"].is_a?(Array)
          end

          check "must contain at least one plan" do
            data["plans"].size >= 1
          end

          data["plans"].each_with_index do |plan, n|

            desc "at #{n} -", plan do |plan|

              desc "`name`" do
                check "must exist" do
                  plan.has_key?("name")
                end
              end

              desc "`price`" do

                check "must exist" do
                  plan.has_key?("price")
                end

                check "must be an integer" do
                  plan["price"].to_s =~ /^\d+$/
                end

              end

              desc "`price_unit`" do

                check "must exist" do
                  plan.has_key?("price_unit")
                end

                valid_price_units = %w|month dyno_hour|
                check "must be [#{valid_price_units.join("|")}]" do
                  valid_price_units.include?(plan["price_unit"])
                end

              end

            end

          end

        end

      rescue Yajl::ParseError => boom
        errors boom.message
      end

      def desc(msg, o=nil, &blk)
        temp, @desc = @desc, "#{@desc}#{msg} "
        yield o
      rescue CheckFailure => boom
        errors boom.message
      ensure
        @desc = temp
      end

      def check(msg)
        raise CheckFailure, "#{@desc}#{msg}" if !yield
      end

      def errors(msg=nil)
        @errors ||= [] if msg
        @errors << msg if msg
        @errors
      end

    end

  end

end