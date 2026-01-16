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
                
                // Date Range Filter Menu
                Menu {
                    ForEach(DateRange.allCases) { range in
                        Button(action: {
                            withAnimation {
                                viewModel.selectedDateRange = range
                                // Fetch is triggered by didSet in ViewModel
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
            
            // Swipeable Charts
            TabView(selection: $selectedTab) {
                
                // 1. Patient Footfall (Line Graph)
                AnalyticsLineChartCard(
                    title: "Patient Footfall",
                    data: viewModel.footfallData,
                    color: .blue
                )
                .padding(.horizontal)
                .tag(0)
                
                // 2. Busiest Doctor (Line Graph)
                AnalyticsDoctorLineChartCard(
                    title: "Busiest Doctor",
                    data: viewModel.busiestDoctorData,
                    color: .purple
                )
                .padding(.horizontal)
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 320)
        }
    }
}

struct AnalyticsLineChartCard: View {
    let title: String
    let data: [AnalyticsData]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.primaryText)
            
            if data.isEmpty {
                Spacer()
                Text("No data for this period")
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Count", item.value)
                        )
                        .foregroundStyle(color.gradient)
                        .interpolationMethod(.catmullRom)
                        .symbol {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                        }
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Count", item.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .padding(.vertical, 10)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(Theme.gridLine)
                        AxisValueLabel().foregroundStyle(Theme.secondaryText)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.gridLine)
                        AxisValueLabel(format: .dateTime.day().month(), centered: true)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }
}

struct AnalyticsDoctorLineChartCard: View {
    let title: String
    let data: [BarChartData]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.primaryText)
            
            if data.isEmpty {
                Spacer()
                Text("No data for this period")
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Doctor", item.label),
                            y: .value("Appointments", item.value)
                        )
                        .foregroundStyle(color.gradient)
                        .interpolationMethod(.catmullRom)
                        .symbol {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                        }
                        
                        AreaMark(
                            x: .value("Doctor", item.label),
                            y: .value("Appointments", item.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .padding(.vertical, 10)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(Theme.gridLine)
                        AxisValueLabel().foregroundStyle(Theme.secondaryText)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }
}
