//
//  ProspectsView.swift
//  Hot Prospects
//
//  Created by Umair on 20/05/24.
//

import CodeScanner
import SwiftData
import SwiftUI
import UserNotifications

struct ProspectsView: View {
    enum FilterType{
        case none,contacted,uncontacted
    }
    
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Prospect.name) var prospect:[Prospect]
    @State private var isShowingScanner = false
    @State private var selectedProspects = Set<Prospect>()
    
    let filter : FilterType
    
    var title:String{
        switch filter {
        case .none:
            "Eveyone"
        case .contacted:
            "Contacted people"
        case .uncontacted:
            "Uncontacted people"
        }
    }
    
    var body: some View {
        NavigationStack{
            List(prospect, selection: $selectedProspects){ prospect in
                VStack(alignment: .leading){
                    Text(prospect.name)
                        .font(.headline)
                    Text(prospect.emailAddress)
                        .foregroundStyle(.secondary)
                }
                .swipeActions{
                    Button("Delete",systemImage:"trash",role:.destructive){
                        modelContext.delete(prospect)
                    }
                    if prospect.isContacted{
                        Button("Mark Uncontacted", systemImage: "person.crop.circle.badge.questionmark"){
                            prospect.isContacted.toggle()
                        }
                        .tint(.blue)
                    } else {
                        Button("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark"){
                            prospect.isContacted.toggle()
                        }
                        .tint(.green)
                        
                        Button("Remind me", systemImage: "bell"){
                            addNotification(for: prospect)
                        }
                        .tint(.orange)
                    }
                }
                .tag(prospect)
            }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Scan", systemImage: "qrcode.viewfinder") {
                            isShowingScanner = true
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                    
                    if selectedProspects.isEmpty == false {
                        ToolbarItem(placement: .bottomBar) {
                            Button("Delete Selected", action: delete)
                        }
                    }
                }
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr],simulatedData: "UmairAnsari\numairansari21@gmail.com", completion: handleScan)
                }
        }
    }
    init (filter : FilterType){
        self.filter = filter
        if filter != .none{
            let ShowContentOnly = filter == .contacted
            _prospect = Query(filter: #Predicate{ $0.isContacted == ShowContentOnly
            }, sort: [SortDescriptor(\Prospect.name)])
        }
    }
    func handleScan(result : Result<ScanResult,ScanError>){
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            let person = Prospect(name: details[0], emailAddress: details[1], isContacted: false)
            modelContext.insert(person)
            
        case .failure(let error):
            print("Scanning Failed : \(error.localizedDescription)")
        }
    }
    func delete(){
        for prospect in selectedProspects{
            modelContext.delete(prospect)
        }
    }
    func addNotification(for prospect: Prospect) {
        let centre = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
//            var dateComponents = DateComponents()
//            dateComponents.hour = 9
//            
//             let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            centre.add(request)
        }
        centre.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                centre.requestAuthorization(options: [.alert,.badge,.sound]) {
                    success, error in
                    if success {
                        addRequest()
                    } else if let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    ProspectsView(filter: .none)
}
