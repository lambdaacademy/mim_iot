defmodule UcaLib.Eventing do
  @moduldoc """
  Provides functionality required for UPnP+ Eventing step.

  ## Examples:

      alias UcaLib.Eventing
      subitem = Eventing.xml_node("subitem", [], [Eventing.xml_node_content("hello")])
      item = Eventing.xml_node("item", [{"id", "12345"}],[subitem])

  The aforementioned example corresponds to the folowing XML:

      <item id='12345'><subitem>hello</subitem></item>

  """
  use Romeo.XML

  @doc """
  Generates an xmlel record.
  """
  def xml_node(name, attrs, children) do
    xmlel(name: name, attrs: attrs, children: children)
  end

  @doc """
  Generates an xmlcdata record.
  """
  def xml_node_content(content), do: xmlcdata(content: content)

end
