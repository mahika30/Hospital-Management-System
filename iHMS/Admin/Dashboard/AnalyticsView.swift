import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
       
            HStack {
                Text("Analytics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primaryText)
                
                Spacer()
                
             
                Menu {
                    ForEach(DateRange.allCases) { range in
                        Button(action: {
                            withAnimation {
                                viewModel.selectedDateRange = range
                                viewModel.updateAnalytics(range: range)
                            }
                        }) {
                            HStack {
                                Text(range.rawValue)
                                if viewModel.selectedDateRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedDateRange.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.surface)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
         
            TabView(selection: $selectedTab) {
                AnalyticsChartCard(title: "Revenue", data: viewModel.revenueData, color: .white, isCurrency: true)
                    .tag(0)
                
                AnalyticsChartCard(title: "Footfall", data: viewModel.footfallData, color: .white, isCurrency: false)
                    .tag(1)
                
                AnalyticsChartCard(title: "Appointments", data: viewModel.revenueData, color: .white, isCurrency: false) // Reusing mock data for demo
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 300)
        }
    }
}

struct AnalyticsChartCard: View {
    let title: String
    let data: [AnalyticsData]
    let color: Color
    let isCurrency: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.primaryText)
            
            if data.isEmpty {
                Spacer()
                Text("No data available")
                    .foregroundColor(Theme.secondaryText)
                Spacer()
            } else {
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Value", item.value)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                        .symbol {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(Theme.gridLine)
                        AxisValueLabel() {
                            if let intValue = value.as(Int.self) {
                                Text("\(isCurrency ? "$" : "")\(intValue)")
                                    .foregroundColor(Theme.secondaryText)
                                    .font(.caption)
                            } else if let doubleValue = value.as(Double.self) {
                                Text("\(isCurrency ? "$" : "")\(Int(doubleValue))")
                                    .foregroundColor(Theme.secondaryText)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.gridLine)
                        AxisValueLabel(format: .dateTime.day().month(), centered: true)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .chartBackground { proxy in
                     Theme.surface
                }
            }
        }
        .padding(20)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
        .padding(.horizontal)
    }
}
