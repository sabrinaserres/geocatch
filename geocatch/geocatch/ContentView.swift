// ContentView.swift
//  geocatch
//
//  Created by Sabrina Serres on 02/05/2023.
//

import SwiftUI
import MapKit
//import CoreLocation
import Combine




struct BlankView: View {
    @State private var avatar: String = "default-avatar"
    @State private var showingPageView = false
    
    var body: some View {
        VStack {
            Text("Hello player! To add a new hiding spot, click on Continue.")
            
            Button("Continue") {
                showingPageView = true
            }
            .foregroundColor(.white)
            .frame(width: 300, height: 50)
            .background(Color.black)
            .cornerRadius(10)
        }
        .navigationTitle("First Step")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPageView) {
            PageView()
        }
    }
}


struct HidingSpot: Identifiable {
    var id = UUID()
    var longitude: String
    var latitude: String
    var difficulty: Int
    var description: String
    var username: String
}

struct PageView: View {
    @State private var avatar: String = "default-avatar"
    @State private var longitude = ""
    @State private var latitude = ""
    @State private var username = ""
    @State private var difficulty = 1
    @State private var description = ""
    @State private var isShowingBanner = false
   

    @State private var hidingSpots: [HidingSpot] = []
   

    let difficulties = [1, 2, 3, 4, 5]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 44.80598,
            longitude: -0.60541),
        span: MKCoordinateSpan(
            latitudeDelta:0.01,
            longitudeDelta: 0.01))

    var body: some View {
        NavigationView {
            VStack {

                HStack {
                    Text("GPS coordinates *")
                    Spacer()
                }
                HStack {
                    TextField("Longitude", text: $longitude)
                    TextField("Latitude", text: $latitude)
                }
                .padding()

                HStack {
                    Text("Username *")
                    Spacer()
                }
                HStack {
                    TextField("Enter username *", text: $username)
                }
                .padding()

                HStack {
                    Text("Difficulty *")
                    Spacer()
                }
                HStack {
                    Picker(selection: $difficulty, label: Text("")) {
                        ForEach(difficulties, id: \.self) {
                            Text(String($0))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()

                HStack {
                    Text("Description")
                    Spacer()
                }
                HStack {
                    TextField("Enter description", text: $description)
                }
                .padding()

                Spacer()

                HStack {
                    Text("* Required fields")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()

                    Button(action: {
                        addNewHidingSpot(longitude: Double(longitude) ?? 0, latitude: Double(latitude) ?? 0, username: username, difficulty: difficulty, description: description, isShowingBanner: isShowingBanner) { result in
                            switch result {
                            case .success: break
                                // handle success case
                            case .failure(let error):
                                // handle error case
                                print(error.localizedDescription)
                            }
                        }
                    }) {
                        Text("Add a hiding spot")
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }


                }
            }
            .padding()
            .overlay(
                // Use Group to show banner message only when isShowingBanner is true
                Group {
                    if $isShowingBanner.wrappedValue {
                        Text("New hiding spot available. Go back to map to see.")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                            .padding(.top, 10)
                    }
                }
                , alignment: .top)
        }
    }
}

func addNewHidingSpot(longitude: Double, latitude: Double, username: String, difficulty: Int, description: String, isShowingBanner: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
    // let url = URL(string: "http://192.168.1.17:3000/api/caches")!
    let url = URL(string: "http://192.168.62.39:3000/api/caches")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let newHidingSpot = [        "latitude": latitude,        "longitude": longitude,        "username": username,        "difficulty": difficulty,        "description": description    ] as [String : Any]
    
    guard let jsonData = try? JSONSerialization.data(withJSONObject: newHidingSpot, options: []) else {
        completion(.failure(NSError(domain: "serialization_error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not serialize new hiding spot data"])))
        return
    }
    
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard error == nil else {
            completion(.failure(error!))
            return
        }
        guard let data = data, let response = response as? HTTPURLResponse else {
            completion(.failure(NSError(domain: "response_error", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data or response"])))
            return
        }
        
        guard (200...299).contains(response.statusCode) else {
            completion(.failure(NSError(domain: "http_error", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP status code \(response.statusCode)"])))
            return
        }
        
        DispatchQueue.main.async {
            completion(.success(()))
        }
    }
    task.resume()
}







class MKPointAnnotationWithID: MKPointAnnotation, Identifiable {
    var id = UUID()
}

struct MapView: View {
    @State private var avatar: String = "default-avatar"
    @Binding var coordinateRegion: MKCoordinateRegion
    @State private var showingBlankView = false
    @State private var showingProfileView = false
    @State private var annotations: [MKPointAnnotationWithID] = []
    @State private var locationManager = CLLocationManager()
    
    let mapTypes = ["Standard", "Satellite", "Hybrid"]
    @State private var selectedMapTypeIndex = 0
    
    // New state to track selected annotation
    @State private var selectedAnnotation: MKPointAnnotationWithID?
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $coordinateRegion, interactionModes: [.all], showsUserLocation: true, userTrackingMode: .constant(.follow), annotationItems: annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .onTapGesture {
                            selectedAnnotation = annotation
                        }
                }
            }
            .edgesIgnoringSafeArea(.all)
            //.onAppear {
            //    locationManager.requestWhenInUseAuthorization()
            //  }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let newAnnotation = MKPointAnnotationWithID()
                        newAnnotation.coordinate = coordinateRegion.center
                        annotations.append(newAnnotation)
                        showingBlankView = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
                    .padding(.trailing)
                }
                NavigationLink(
                    destination: BlankView(),
                    isActive: $showingBlankView,
                    label: {
                        EmptyView()
                    })
                HStack {
                    Spacer()
                    Button(action: {
                        showingProfileView = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
                    .padding(.trailing)
                }
                NavigationLink(
                    destination: ProfileView(loggedInUsername: .constant(nil)),
                    isActive: $showingProfileView,
                    label: {
                        EmptyView()
                    })
                Spacer()
            }
            
            // Show selected annotation in pop-up
            if let annotation = selectedAnnotation {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedAnnotation = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        .padding(.trailing)
                    }
                    Spacer()
                    Text("Hiding Spot")
                        .font(.title)
                    Text("Lat: \(annotation.coordinate.latitude)\nLong: \(annotation.coordinate.longitude)/nCreator:/n Difficulty:")
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .shadow(radius: 5)
                .frame(width: 250, height: 200)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            }
            
            VStack {
                Spacer()
                Picker(selection: $selectedMapTypeIndex, label: Text("Map Type")) {
                    ForEach(0 ..< mapTypes.count) {
                        Text(mapTypes[$0]).tag($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .background(Color.black.opacity(0.05))
            }
        }
    }
}

struct PopupView: View {
    let annotation: MKPointAnnotationWithID
    @Binding var isPresented: MKPointAnnotationWithID?

    var body: some View {
        ZStack {
            Color.white.opacity(0.8)
            VStack {
                Text("Popup content here")
                Button(action: {
                    isPresented = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
        }
        .frame(width: 200, height: 200)
        .cornerRadius(10)
        .position(mapView.convert(annotation.coordinate, toPointTo: mapView))
    }

    private var mapView: MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
}







struct ProfileView: View {
    @State private var showingHidingSpots = false
    @Binding var loggedInUsername: String?
    @State private var showingContentView = false
    @State private var showingAvatarSelectionView = false
    @State private var avatar: String = "default-avatar"
    
    var body: some View {
        VStack {
            HStack {
                Text("\(loggedInUsername ?? "") Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                Spacer()
            }
            Spacer()
            Button(action: {
                showingAvatarSelectionView = true
            }) {
                Image(avatar)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
            }
            .buttonStyle(PlainButtonStyle()) // Remove button default styling
            NavigationLink(
                destination: AvatarSelectionView(selectedAvatar: $avatar),
                isActive: $showingAvatarSelectionView,
                label: {
                    EmptyView()
                })
            Button(action: {
                showingHidingSpots = true
            }) {
                Text("My Hiding Spots")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
            }
            NavigationLink(
                destination: HidingSpotListView(),
                isActive: $showingHidingSpots,
                label: {
                    EmptyView()
                })
            Spacer()
            Button(action: {
                logoutUser()
                loggedInUsername = nil
                showingContentView = true
            }) {
                Text("Log Out")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            NavigationLink(
                destination: ContentView(),
                isActive: $showingContentView,
                label: {
                    EmptyView()
                })
            Spacer()
        }
    }
}
    
func logoutUser() {
    guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found, user is not logged in")
        return
    }
   // let url = URL(string: "http://192.168.1.17:3000/api/users/logout")!
    let url = URL(string: "http://192.168.62.39:3000/api/users/logout")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error in logout request: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        do {
            let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
            guard let responseDict = responseJSON as? [String: Any] else {
                print("Error parsing logout response: unexpected response format")
                return
            }
            if let message = responseDict["message"] as? String {
                print(message)
                // Remove auth token from UserDefaults
                UserDefaults.standard.removeObject(forKey: "authToken")
                DispatchQueue.main.async {
                    // Terminate the app
                    UIControl().sendAction(#selector(NSXPCConnection.suspend),
                                           to: UIApplication.shared, for: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                        exit(EXIT_SUCCESS)
                    })
                }
            } else {
                print("Error parsing logout response: unexpected response format")
            }
        } catch {
            print("Error parsing logout response: \(error.localizedDescription)")
        }
    }.resume()
}




struct AvatarSelectionView: View {
    @Binding var selectedAvatar: String
    private let avatarNames = ["avatar1", "avatar2", "avatar3", "avatar4", "avatar5", "avatar6"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select an avatar:")
                .font(.title)
                .fontWeight(.bold)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(avatarNames, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(selectedAvatar == name ? Color.blue : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedAvatar = name
                            }
                    }
                }
                .padding()
            }
            Button(action: {
                // Save selected avatar and go back to profile view
            }) {
                Text("Save")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct HidingSpotListView: View {
    var body: some View {
        Text("Hiding View")
    }
}




struct Signin {
    
    // cette struct sera transmise a la base elle contient les valeurs
    var username: String
    var password: String
    var mail: String
   
}

struct SigninView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var mail = ""
    @State private var wrongUsername = false
    @State private var wrongPassword = false
    @State private var wrongMail = false
    
    var body: some View {
        ZStack{
            Image("launchscreengeocatch")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack {
                TextField("Username", text: $username)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(wrongUsername ? Color.red : Color.clear, lineWidth: 2))
                    .keyboardType(.alphabet)
                
                SecureField("Password", text: $password)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(wrongPassword ? Color.red : Color.clear, lineWidth: 2))
                    .keyboardType(.numbersAndPunctuation)
                
                TextField("Email", text: $mail)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(wrongMail ? Color.red : Color.clear, lineWidth: 2))
                    .keyboardType(.emailAddress)
                
                Button(action: {
                    createNewUser(username: self.username, email: self.mail, password: self.password)
                }) {
                    Text("Sign in")
                        .foregroundColor(.white)
                        .frame(width: 300, height: 50)
                        .background(Color.black)
                        .cornerRadius(10)
                }
            }
        }
    }
}

func createNewUser(username: String, email: String, password: String) {
    //let url = URL(string: "http://192.168.1.17:3000/api/users")!
    let url = URL(string: "http://192.168.62.39:3000/api/users")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let parameters = ["username": username, "email": email, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        if let responseJSON = responseJSON as? [String: Any] {
            debugPrint(responseJSON)
            print(String(data: data, encoding: .utf8) ?? "No data")

        }
    }.resume()
}




struct ContentView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var wrongUsername = false
    @State private var wrongPassword = false
    @State private var showingLoginScreen = false
    @State private var showingSigninScreen = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 44.80598,
            longitude: -0.60541),
        span: MKCoordinateSpan(
            latitudeDelta:0.01,
            longitudeDelta: 0.01))
    @State private var loggedInUsername: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("launchscreengeocatch")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                VStack {
                    Text("GeoCatch")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    
                    TextField("Username", text: $username)
                        .padding()
                        .frame(width: 300, height: 50)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(wrongUsername ? Color.red : Color.clear, lineWidth: 2))
                        .keyboardType(.alphabet)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .frame(width: 300, height: 50)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(wrongPassword ? Color.red : Color.clear, lineWidth: 2))
                        .keyboardType(.numbersAndPunctuation)
                    
                    Button("Log in") {
                        authenticateUser2(username: username, password: password)
                        print("page accueil valeur \(showingLoginScreen)")
                    }
                    .foregroundColor(.white)
                    .frame(width: 300, height: 50)
                    .background(Color.black)
                    .cornerRadius(10)
                    
                    NavigationLink(
                        destination: SigninView(),
                        isActive: $showingSigninScreen
                    ) {
                        Text("New to GeoCatch? Create an account")
                            .padding()
                            .foregroundColor(.black)
                    }
                }
                
                NavigationLink(
                    destination: MapView(coordinateRegion: $region),
                    isActive: $showingLoginScreen,
                    label: {
                        EmptyView()
                    })
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .opacity(showingLoginScreen ? 1 : 0)
                
                
                
            }
        }
    }
    
    func authenticateUser2(username: String, password: String) {
       // let url = URL(string: "http://192.168.1.17:3000/api/users/authenticate")!
        let url = URL(string: "http://192.168.62.39:3000/api/users/authenticate")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody = ["username": username, "password": password]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Error creating HTTP request body")
            return
        }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error in authentication request: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                guard let responseDict = responseJSON as? [String: Any] else {
                    print("Error parsing authentication response: unexpected response format")
                    return
                }
                if let token = responseDict["token"] as? String {
                    // Save token to UserDefaults
                    UserDefaults.standard.set(token, forKey: "authToken")
                    DispatchQueue.main.async {
                        self.showingLoginScreen = true
                        print("func valeur \(showingLoginScreen)")
                        
                    }
                    
                    // Now that we have the token, we can use it to access protected resources
                   // let url = URL(string: "http://192.168.1.17:3000/api/users/authenticate")!
                    let url = URL(string: "http://192.168.62.39:3000/api/users/authenticate")!
                    var request = URLRequest(url: url)
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        guard let data = data, error == nil else {
                            print("Error accessing protected resource: \(error?.localizedDescription ?? "Unknown error")")
                            return
                        }
                        
                        // Parse response data here...
                        
                    }.resume()
                } else if let message = responseDict["message"] as? String {
                    if message.contains("username") {
                        DispatchQueue.main.async {
                            self.wrongUsername = true
                        }
                    }
                    if message.contains("password") {
                        DispatchQueue.main.async {
                            self.wrongPassword = true
                        }
                    }
                } else {
                    print("Error parsing authentication response: unexpected response format")
                }
            } catch {
                print("Error parsing authentication response: \(error.localizedDescription)")
            }
        }.resume()
    }




    

}

func addapinpoint(longitude: String, latitude: String){
    /// convert string to int
    /// fonction qui genere les long et lat en int  pour apres les ajouter
    /// function qui intervient lors de l'appui du button submit dans la page d'info
    
}
    
    
    
    class UserAuth: ObservableObject {
        @Published var isLoggedIn: Bool = false
        @Published var username: String = ""
        
       // func authenticateUser(username: String, password: String) -> Bool {
            // Ajoutez votre logique d'authentification ici.
            // Si l'authentification réussit, mettez à jour les variables d'état et renvoyez true.
            // Sinon, renvoyez false.
        //}
        
       // func logoutUser() {
            // Mettez à jour les variables d'état pour indiquer que l'utilisateur est déconnecté.
        //    isLoggedIn = false
         //   username = ""
      //  }
    }


    


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




