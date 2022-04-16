import SwiftUI
import Charts

/**
  1軸のデータを保持するクラス
 */
class OneAxisData: ObservableObject {
    @Published var chartDataEntry : [ChartDataEntry] = []
}
 

/**
  3つの折れ線データを描画するクラス
 */
struct LineChart : UIViewRepresentable {
    @ObservedObject var irData: OneAxisData
    @State var chart = LineChartView()
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        updateChartData()

    }

    func makeUIView(context: Context) -> LineChartView {
        // グラフに表示する要素
        let data = LineChartData()
        //x
        let dataSet = LineChartDataSet(entries: irData.chartDataEntry, label: "IR")
        dataSet.mode = .cubicBezier
        dataSet.drawCirclesEnabled = false
        dataSet.setColor(.red)
        dataSet.drawValuesEnabled = false

        // データセットを作ってチャートに反映
        data.addDataSet(dataSet)
        chart.data = data

        return chart
    }
    
    func updateChartData(){
        // update
        let data = LineChartData()
        //x
        let dataSet = LineChartDataSet(entries: irData.chartDataEntry, label: "IR")
        dataSet.mode = .cubicBezier
        dataSet.drawCirclesEnabled = false
        dataSet.setColor(.red)
        dataSet.drawValuesEnabled = false

        // データセットを作ってチャートに反映
        data.addDataSet(dataSet)
        chart.data = data
    }
}


struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()
    @ObservedObject var irData = OneAxisData()
    @State var count = 1

    var body: some View {
        VStack (spacing: 10) {
            Text("Heart Rate Graph")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .center)
            List(bleManager.peripherals) { peripheral in
                HStack {
                    Text(peripheral.name)
                    Spacer()
                    Text(String(peripheral.rssi))
                }
            }.frame(height: 100)

                .font(.headline)
            LineChart(irData: irData)
                .onChange(of: self.bleManager.value) { value in
                    print(value)
                    if(irData.chartDataEntry.count > 30){
                        irData.chartDataEntry.removeFirst()
                    }
                    var val: Double! = value[0]
                    if(irData.chartDataEntry.count > 0){
                        var val_last: Double! = irData.chartDataEntry.last?.y
                        if(val < 50){
                            if(abs(val - val_last) > 10){
                                val = val_last
                            }
                        }
                    }
                    if(val > 300){
                        //300以上はおかしいので固定
                        val = 300
                    }
                    irData.chartDataEntry.append(ChartDataEntry(x: Double(Double(count) / 100.0), y: val))
                    count += 1

                }


            Spacer()

            HStack {
                VStack (spacing: 20) {
                    Button(action: {
                        self.bleManager.startScanning()
                    }) {
                        Text("Start Scan")
                            .padding()
                            .border(Color.blue, width: 1)
                    }
                    Button(action: {
                        self.bleManager.stopScanning()
                    }) {
                        Text("Stop Scan")
                            .padding()
                            .border(Color.blue, width: 1)
                    }
                }.padding()

                Spacer()

                VStack (spacing: 20) {
                    Button(action: {
                        irData.chartDataEntry.removeAll()
                        let data = Data(_: [0x31, 0x31, 0x31, 0x31])
                        self.bleManager.myPeripheral.writeValue(data , for: self.bleManager.writeCharacteristic!, type: .withResponse)
                    }) {
                        Text("Start Record")
                            .padding()
                            .border(Color.blue, width: 1)
                    }
                    Button(action: {
                        let data = Data(_: [0x32, 0x32, 0x32, 0x32])
                        self.bleManager.myPeripheral.writeValue(data , for: self.bleManager.writeCharacteristic!, type: .withResponse)
                    }) {
                        Text("Stop Record")
                            .padding()
                            .border(Color.blue, width: 1)
                    }
                }.padding()
            }
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
