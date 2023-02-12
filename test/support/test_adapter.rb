class TestAdapter
  # Iterates through each of the required methods of a response adapter and
  # defines a method which just returns the parameter.
  %i[render_json render_xml render_text render_pdf render_csv render_nothing set_header]
    .each do |adapter_method|
      define_singleton_method(adapter_method) do |entity|
        entity
      end
    end
end
