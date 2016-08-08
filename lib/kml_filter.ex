defmodule KmlFilter do
  require Logger
  import SweetXml

  def main(_args) do
    doc   = File.read!("kml/doc.kml")
    total = File.read!("kml/total.kml")
    minsk_zhodino_big = File.read!("kml/minsk_zhodino_big.kml")
    process(doc, total, minsk_zhodino_big)
  end

  def append0(e) do
    e
    |> String.reverse
    |> String.rjust(9, ?0)
    |> String.reverse
  end

  def transform_coordinates(coordinates) do
    coordinates
    |> String.replace_suffix(",0.00", ",0.0")
    |> String.split(",")
    |> (fn([e1, e2, e3]) -> [append0(e1), append0(e2), e3] end).()
    |> Enum.join(",")
  end

  def doc_to_set(doc) do
    doc
    |> extract_points
    |> Stream.map(&to_string/1)
    |> Stream.map(&transform_coordinates/1)
    |> MapSet.new
  end

  def to_kml_map(doc) do
    doc |> xpath(
      ~x"//Document/Placemark"l,
      name: ~x"./name/text()"s,
      styleUrl: ~x"./styleUrl/text()"s,
      description: ~x"./description/text()"s,
      coordinates: ~x"./Point/coordinates/text()"s |> transform_by(&transform_coordinates/1),
    )
  end

  def process(doc, total, minsk_zhodino_big) do
    docSet = doc |> doc_to_set
    totalSet = total |> doc_to_set
    minskZhodinoSet = minsk_zhodino_big |> to_kml_map

    for_remove = MapSet.difference(totalSet, docSet)
    produce_new_kml(minskZhodinoSet, for_remove)
  end

  def print_set(set) do
    set
    |> MapSet.to_list
    |> length
    |> Logger.info
  end

  def extract_points(doc) do
    doc
    |> xpath(~x"//Document/Placemark/Point/coordinates/text()"l)
  end

  def point_to_xml(point) do
    """
    <Placemark>
      <description>#{point.description}</description>
      <styleUrl>#{point.styleUrl}</styleUrl>
      <name>#{point.name}</name>
      <Point>
        <coordinates>#{point.coordinates}</coordinates>
      </Point>
    </Placemark>
    """
  end

  def write_kml_points(f, big, remove) do
    remove_set = MapSet.new(remove)
    count = big
    |> Enum.reduce(0, fn(point, acc) ->
      if !MapSet.member?(remove_set, point.coordinates) do
        IO.binwrite(f, point_to_xml(point))
        acc + 1
      else
        acc
      end
    end)
    Logger.info count
  end

  def produce_new_kml(big, remove) do
    {:ok, f} = File.open("kml/new.kml", [:write])
    IO.binwrite(f, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Document>\n")

    write_kml_points(f, big, remove)

    IO.binwrite(f, "\n<Style id=\"none-inactive\"><IconStyle><Icon><href>http://www.gstatic.com/mapspro/images/stock/959-wht-circle-blank.png</href></Icon><color>B00066FF</color></IconStyle><LabelStyle><scale>0</scale></LabelStyle><BalloonStyle><text><![CDATA[$[description]]]></text></BalloonStyle></Style><Style id=\"none-active\"><IconStyle><Icon><href>http://www.gstatic.com/mapspro/images/stock/959-wht-circle-blank.png</href></Icon><color>B00066FF</color></IconStyle><LabelStyle><scale>1</scale></LabelStyle><BalloonStyle><text><![CDATA[$[description]]]></text></BalloonStyle></Style><StyleMap id=\"none\"><Pair><key>normal</key><styleUrl>#none-inactive</styleUrl></Pair><Pair><key>highlight</key><styleUrl>#none-active</styleUrl></Pair></StyleMap><Style id=\"res-inactive\"><IconStyle><Icon><href>http://www.gstatic.com/mapspro/images/stock/959-wht-circle-blank.png</href></Icon><color>B0D09205</color></IconStyle><LabelStyle><scale>0</scale></LabelStyle><BalloonStyle><text><![CDATA[$[description]]]></text></BalloonStyle></Style><Style id=\"res-active\"><IconStyle><Icon><href>http://www.gstatic.com/mapspro/images/stock/959-wht-circle-blank.png</href></Icon><color>B0D09205</color></IconStyle><LabelStyle><scale>1</scale></LabelStyle><BalloonStyle><text><![CDATA[$[description]]]></text></BalloonStyle></Style><StyleMap id=\"res\"><Pair><key>normal</key><styleUrl>#res-inactive</styleUrl></Pair><Pair><key>highlight</key><styleUrl>#res-active</styleUrl></Pair></StyleMap><Style id=\"enl-inactive\"><IconStyle><Icon><href>http://www.gstatic.com/mapspro/images/stock/959-wht-circle-blank.png</href></Icon><color>B002BF02</color></IconStyle><LabelStyle><scale>0</scale></LabelStyle><BalloonStyle><text><![CDATA[$[description]]]></text></BalloonStyle></Style><Style id=\"enl-active\"><IconStyle><Icon><href>http://www.gstatic.com/mapspro/images/stock/959-wht-circle-blank.png</href></Icon><color>B002BF02</color></IconStyle><LabelStyle><scale>1</scale></LabelStyle><BalloonStyle><text><![CDATA[$[description]]]></text></BalloonStyle></Style><StyleMap id=\"enl\"><Pair><key>normal</key><styleUrl>#enl-inactive</styleUrl></Pair><Pair><key>highlight</key><styleUrl>#enl-active</styleUrl></Pair></StyleMap>\n</Document>\n</kml>")
    File.close(f)
  end

end
