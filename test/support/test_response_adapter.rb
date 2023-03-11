class TestResponseAdapter
  def self.render_json(entity)
    mock_render(entity)
  end

  def self.render_xml(entity)
    mock_render(entity)
  end

  def self.render_pdf(entity)
    mock_render(entity)
  end

  def self.render_csv(entity)
    mock_render(entity)
  end

  def self.render_text(entity)
    mock_render(entity)
  end

  def self.render_nothing(entity)
    mock_render(entity)
  end

  # mock response
  def self.mock_render(entity)
    entity
  end
end
