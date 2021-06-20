require 'prawn'
require 'prawn/table'

module Receipts
  class Invoice < Prawn::Document
    attr_reader :attributes, :id, :company, :custom_font, :line_items, :logo, :message, :product, :subheading, :bill_to, :issue_date, :due_date, :status

    def initialize(attributes)
      @attributes  = attributes
      @id          = attributes.fetch(:id)
      @company     = attributes.fetch(:company)
      @line_items  = attributes.fetch(:line_items)
      @custom_font = attributes.fetch(:font, {})
      @message     = attributes.fetch(:message) { default_message }
      @subheading  = attributes.fetch(:subheading) { default_subheading }
      @bill_to     = Array(attributes.fetch(:bill_to)).join("\n")
      @issue_date  = attributes.fetch(:issue_date)
      @due_date    = attributes.fetch(:due_date)
      @status      = attributes.fetch(:status)
      @due_date_name      = attributes.fetch(:due_date_name)
      @bill_to_name       = attributes.fetch(:bill_to_name)
      @invoice_date_name  = attributes.fetch(:invoice_date_name)
      @invoice_name       = attributes.fetch(:invoice_name)
      @status_name        = attributes.fetch(:status_name)

      super(margin: 0)

      setup_fonts if custom_font.any?
      generate
    end

    private

      def default_message
        "For questions, contact us anytime at <color rgb='326d92'><link href='mailto:#{company.fetch(:email)}?subject=Charge ##{id}'><b>#{company.fetch(:email)}</b></link></color>."
      end

      def default_subheading
        "#{@invoice_name || 'INVOICE'} #%{id}"
      end

      def setup_fonts
        font_families.update "Primary" => custom_font
        font "Primary"
      end

      def generate
        bounding_box [0, 792], width: 612, height: 792 do
          bounding_box [85, 792], width: 442, height: 792 do
            header
            charge_details
            footer
          end
        end
      end

      def header
        move_down 60

        logo = company[:logo]

        if logo.nil?
          move_down 32
        elsif logo.is_a?(String)
          image open(logo), height: 32
        else
          image logo, height: 32
        end

        move_down 8
        label (subheading % {id: id})

        move_down 10

        # Cache the Y value so we can have both boxes at the same height
        top = y
        bounding_box([0, y], width: 200) do
          label @bill_to_name || "BILL TO"

          move_down 5
          text_box bill_to, at: [0, cursor], width: 200, height: 75, inline_format: true, size: 10, leading: 4, overflow: :shrink_to_fit

        end

        bounding_box([250, top], width: 200) do
          label @invoice_date_name || "INVOICE DATE"

          move_down 5
          text issue_date.to_s, inline_format: true, size: 12, leading: 4

          move_down 10
          label @due_date_name || "DUE DATE"

          move_down 5
          text due_date.to_s, inline_format: true, size: 12, leading: 4

          move_down 10
          label @status_name || "STATUS"

          move_down 5
          text status, inline_format: true, size: 12, leading: 4
        end
      end

      def charge_details
        move_down 30

        borders = line_items.length - 2

        table(line_items, width: bounds.width, cell_style: { border_color: 'cccccc', inline_format: true }) do
          cells.padding = 12
          cells.borders = []
          row(0..borders).borders = [:bottom]
        end
      end

      def footer
        move_down 30
        text message, inline_format: true, size: 12, leading: 4

        move_down 30
        text company.fetch(:name), inline_format: true
        text "<color rgb='888888'>#{company.fetch(:address)}</color>", inline_format: true
      end

      def label(text)
        text "<color rgb='a6a6a6'>#{text}</color>", inline_format: true, size: 8
      end
  end
end
