module Paperclip
  module Storage
    module Async
      def self.extended(base)
        base.extend(Paperclip::Storage::S3)
        base.class_eval { attr_reader :storage_proxy }
        base.instance_eval { @storage_proxy = @options[:storage_proxy] }
      end

      include Paperclip::Storage::S3

      def save
        return if storage_proxy.processing?(name, instance, instance_read(:digest))
        super
      end

      def paths
        [:original, *styles.keys].uniq.map { |style| path(style) }.compact
      end

      def to_file(style = default_style)
        return @queued_for_write[style] if @queued_for_write[style]
        return super unless (proxy = storage_proxy.new(name, instance, instance_read(:digest))).processing?
        file_name = instance.send(:"#{name}_file_name")
        log("  \e[32m\e[1m\e[4mAsync paperclip file name:\e[0m   #{file_name}")
        Tempfile.new([File.basename(file_name), File.extname(file_name)]).tap do |tmp|
          tmp.write(proxy.content)
          tmp.rewind
        end
      end

      def url(style = default_style, include_updated_timestamp = true)
        storage_proxy.processing?(:"#{@name}", @instance, instance_read(:digest)) ? interpolate(@default_url, style) : super
      end
    end
  end
end
