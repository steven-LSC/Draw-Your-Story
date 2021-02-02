import SwiftUI
import Firebase
import PencilKit
import Photos

struct ContentView: View {
    var body: some View {
        Home()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Create Story的主畫面
struct CreateStory : View {

    @State var selected : [SelectedImages] = []
    @State var selected_cloud : [SelectedImages] = []
    @State var show = false
    @State var show_cloud = false
    @Environment(\.presentationMode) var presentationMode
    
    @State var timer_setting :Double = 3.0
    @State var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @State var currentIndex = 0
    @State var play_stop = false
    @State var play_stop_string = "pause"
    
    var body: some View{
        ZStack(alignment: .top){

            Color.black.opacity(0.07).edgesIgnoringSafeArea(.all)

            if !self.selected.isEmpty{
                
                VStack(){
                    Image("lamp")
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width / 5,height: UIScreen.main.bounds.width / 5)

                    TabView(selection: $currentIndex) {
                        ForEach(0..<self.selected.count,id: \.self){num in

                            Image(uiImage: selected[num].image)
                                .resizable()
                                .frame(width: UIScreen.main.bounds.width - 40, height: 400)
                                .tag(num)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(width: UIScreen.main.bounds.width - 40, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding()
                    .onReceive(timer, perform: {_ in
                        currentIndex = currentIndex < self.selected.count ? currentIndex + 1: 0
                    })
                    
                    HStack{
                        
                        Button(action: {
                            self.timer.upstream.connect().cancel()
                            timer_setting+=0.5
                            timer = Timer.publish(every: timer_setting, on: .main, in: .common).autoconnect()
                            print(timer_setting)
                        }, label: {
                            
                            Image("minus")
                                .resizable()
                                .frame(width: 20,height: 20)
                        })
                        .padding(.horizontal,10)
                        
                        Button(action: {
                            
                            if play_stop == false{
                                self.timer.upstream.connect().cancel()
                                play_stop.toggle()
                                play_stop_string = "play"
                            }
                            else{
                                timer = Timer.publish(every: timer_setting, on: .main, in: .common).autoconnect()
                                play_stop.toggle()
                                play_stop_string = "pause"
                            }
                        }, label: {
                            Image(play_stop_string)
                                .resizable()
                                .frame(width: 20,height: 20)
                        })
                        .padding(.horizontal,10)
                        
                        Button(action: {
                            if timer_setting > 0.5{
                                timer_setting -= 0.5
                                self.timer.upstream.connect().cancel()
                                timer = Timer.publish(every: timer_setting, on: .main, in: .common).autoconnect()
                                print(timer_setting)
                            }
                        }, label: {
                            
                            Image("plus")
                                .resizable()
                                .frame(width: 20,height: 20)
                            
                        })
                        .padding(.horizontal,10)
                    }
                    
                }
                .padding(.vertical,100)
            }

            else{
                VStack(){
                    Image("lamp")
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width / 5,height: UIScreen.main.bounds.width / 5)
                }
                .padding(.vertical,100)
            }


            if self.show{
                CustomPicker(selected: self.$selected, show: self.$show)
            }
            
            if self.show_cloud{
                CustomPickerCloud(selected: self.$selected_cloud, show: self.$show_cloud)
            }
            
        }
        .navigationBarTitle(Text(""), displayMode: .inline)
        .edgesIgnoringSafeArea(.bottom)
        // Hide the system back button
        .navigationBarBackButtonHidden(true)
        // Add your custom back button here
        .navigationBarItems(leading:HStack(spacing: 25){

        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label:{

            Image(systemName: "arrow.left")

        })
        .foregroundColor(Color.black.opacity(0.7))

        },trailing:
            HStack(spacing: 25){
                
                Button(action: {

                    self.selected.removeAll()

                    self.show.toggle()
                    
                    self.play_stop_string = "pause"

                }) {
                    Image("photo-album")
                        .resizable()
                        .frame(width: 30,height:30)
                }

                Button(action: {
                    self.selected_cloud.removeAll()
                    self.show_cloud.toggle()
                }) {

                Image("cloud-computing")
                    .resizable()
                    .frame(width: 30,height: 30)
                }
            }
        )
    }
}

// 上傳到雲端的畫面
struct CustomPickerCloud : View {
    
    @Binding var selected : [SelectedImages]
    @State var grid : [[Images]] = []
    @Binding var show : Bool
    @State var disabled = false
    
    func randomString(len:Int) -> String {
        let charSet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let c = Array(charSet)
        var s:String = ""
        for _ in (1...len) {
            s.append(c[Int(arc4random()) % c.count])
        }
        return s
    }

    func upload(index:Int) {

        let storage = Storage.storage()
        let filename = randomString(len: 10) // 用亂碼生成避免重複
        
        storage.reference().child(filename).putData(selected[index].image.jpegData(compressionQuality: 0.35)!, metadata: nil){ (_, err) in

            if err != nil{

                print((err?.localizedDescription)!)
                return
            }
            print(index," success")
        }
    }

    
    var body: some View{
        
        GeometryReader{_ in
            
            VStack{
                

                if !self.grid.isEmpty{
                    
                    HStack{
                        Spacer()
                    }
                    .padding(.leading)
                    .padding(.top)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
                        VStack(spacing: 20){
                            
                            ForEach(self.grid,id: \.self){i in
                                
                                HStack{
                                    
                                    ForEach(i,id: \.self){j in
                                        
                                        Card(data: j, selected: self.$selected)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    Button(action: {
                        
                        for i in 0..<self.selected.count{
                            upload(index: i)
                        }
                        self.show.toggle()
                        
                    }) {
                        
                        Text("Select")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical,10)
                            .frame(width: UIScreen.main.bounds.width / 2)
                    }
                    .background(Color.red.opacity((self.selected.count != 0) ? 1 : 0.5))
                    .clipShape(Capsule())
                    .padding(.bottom)
                    .disabled((self.selected.count != 0) ? false : true)
                    
                }
                else{
                    
                    if self.disabled{
                        
                        Text("Enable Storage Access In Settings !!!")
                    }
                    if self.grid.count == 0{
                        
                        Indicator()
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.5)
            .background(Color.white)
            .cornerRadius(12)
        }
        .background(Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
        .onTapGesture {
        
            self.show.toggle()
            
        })
        .onAppear {
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                if status == .authorized{
                    
                    self.getAllImages()
                    self.disabled = false
                }
                else{
                    
                    print("not authorized")
                    self.disabled = true
                }
            }
        }
    }
    
    func getAllImages(){
        
        let opt = PHFetchOptions()
        opt.includeHiddenAssets = false
        
        let req = PHAsset.fetchAssets(with: .image, options: .none)
        
        DispatchQueue.global(qos: .background).async {
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            
            for i in stride(from: 0, to: req.count, by: 3){
                
                var iteration : [Images] = []
                    
                for j in i..<i+3{
                    
                    if j < req.count{
                        
                        PHCachingImageManager.default().requestImage(for: req[j], targetSize: CGSize(width: 150, height: 150), contentMode: .default, options: options) { (image, _) in
                            
                            let data1 = Images(image: image!, selected: false, asset: req[j])
                            
                            iteration.append(data1)

                        }
                    }
                }
                    
                self.grid.append(iteration)
            }
            
        }
    }
}

// 選擇要播放的草稿的畫面
struct CustomPicker : View {
    
    @Binding var selected : [SelectedImages]
    @State var grid : [[Images]] = []
    @Binding var show : Bool
    @State var disabled = false
    
    var body: some View{
        
        GeometryReader{_ in
            
            VStack{
                

                if !self.grid.isEmpty{
                    
                    HStack{
                        Spacer()
                    }
                    .padding(.leading)
                    .padding(.top)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
                        VStack(spacing: 20){
                            
                            ForEach(self.grid,id: \.self){i in
                                
                                HStack{
                                    
                                    ForEach(i,id: \.self){j in
                                        
                                        Card(data: j, selected: self.$selected)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    Button(action: {
                        
                        self.show.toggle()
                        
                    }) {
                        
                        Text("Select")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical,10)
                            .frame(width: UIScreen.main.bounds.width / 2)
                    }
                    .background(Color.red.opacity((self.selected.count != 0) ? 1 : 0.5))
                    .clipShape(Capsule())
                    .padding(.bottom)
                    .disabled((self.selected.count != 0) ? false : true)
                    
                }
                else{
                    
                    if self.disabled{
                        
                        Text("Enable Storage Access In Settings !!!")
                    }
                    if self.grid.count == 0{
                        
                        Indicator()
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.5)
            .background(Color.white)
            .cornerRadius(12)
        }
        .background(Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
        .onTapGesture {
        
            self.show.toggle()
            
        })
        .onAppear {
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                if status == .authorized{
                    
                    self.getAllImages()
                    self.disabled = false
                }
                else{
                    
                    print("not authorized")
                    self.disabled = true
                }
            }
        }
    }
    
    func getAllImages(){
        
        let opt = PHFetchOptions()
        opt.includeHiddenAssets = false
        
        let req = PHAsset.fetchAssets(with: .image, options: .none)
        
        DispatchQueue.global(qos: .background).async {

           let options = PHImageRequestOptions()
           options.isSynchronous = true
            
          for i in stride(from: 0, to: req.count, by: 3){
                    
                var iteration : [Images] = []
                    
                for j in i..<i+3{
                    
                    if j < req.count{
                        
                        PHCachingImageManager.default().requestImage(for: req[j], targetSize: CGSize(width: 150, height: 150), contentMode: .default, options: options) { (image, _) in
                            
                            let data1 = Images(image: image!, selected: false, asset: req[j])
                            
                            iteration.append(data1)

                        }
                    }
                }
                    
                self.grid.append(iteration)
            }
            
        }
    }
}

// CustomPicker CustomPickerCloud的元件
struct Card : View {
    
    @State var data : Images
    @Binding var selected : [SelectedImages]
    
    var body: some View{
        
        ZStack{
            
            Image(uiImage: self.data.image)
            .resizable()
            
            if self.data.selected{
                
                ZStack{
                    
                    Color.black.opacity(0.5)
                    
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
            }
            
        }
        .frame(width: (UIScreen.main.bounds.width - 80) / 3, height: 90)
        .onTapGesture {
            
            
            if !self.data.selected{

                
                self.data.selected = true
                
                DispatchQueue.global(qos: .background).async {
                    
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    
                    
                    PHCachingImageManager.default().requestImage(for: self.data.asset, targetSize: .init(), contentMode: .default, options: options) { (image, _) in

                        self.selected.append(SelectedImages(asset: self.data.asset, image: image!))
                    }
                }

            }
            else{
                
                for i in 0..<self.selected.count{
                    
                    if self.selected[i].asset == self.data.asset{
                        
                        self.selected.remove(at: i)
                        self.data.selected = false
                        return
                    }
                    
                }
            }
        }
        
    }
}

// CustomPicker CustomPickerCloud的元件
struct Indicator : UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIActivityIndicatorView  {
        
        let view = UIActivityIndicatorView(style: .large)
        view.startAnimating()
        return view
    }
    
    func updateUIView(_ uiView:  UIActivityIndicatorView, context: Context) {
        
        
    }
}

// CustomPicker CustomPickerCloud的元件
struct Images: Hashable {
    
    var image : UIImage
    var selected : Bool
    var asset : PHAsset
}

// CustomPicker CustomPickerCloud的元件
struct SelectedImages: Hashable{
    
    var asset : PHAsset
    var image : UIImage
}

// Draw a Story的主畫面
struct CanvasView : View {
    
    @State var canvas = PKCanvasView()
    @State var isDraw = true
    @State var color : Color = .black
    @State var type : PKInkingTool.InkType = .pencil
    @State var colorPicker = false
    @State var items : [Any] = []
    @State var sheet = false
    
    @Environment(\.presentationMode) var presentationMode
        
    var body: some View {
        
        DrawingView(canvas: $canvas, isDraw: $isDraw,type: $type,color: $color)
        .navigationBarTitle(Text("Canvas"), displayMode: .inline)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:HStack(spacing: 25){
            
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label:{
                Image(systemName: "arrow.left")
                    
            })
            
            
            Button(action: {

                let image = canvas.drawing.image(from: canvas.drawing.bounds, scale: 1)
                items.removeAll()
                items.append(image)
                sheet.toggle()
                

            }, label: {
                Image(systemName: "square.and.arrow.up")
                    
            })
            
            Button(action: {
                SaveImage()
            }, label: {
                Image(systemName: "square.and.arrow.down.fill")
            })
            
        }
        .sheet(isPresented: $sheet, content: {
            ShareSheet(items: items)
        }), trailing: HStack(spacing: 25){
            
            Button(action: {

                

                isDraw = false

            }) {

                Image(systemName: "pencil.slash")
                    
            }
            
            Button(action: {
                
                colorPicker.toggle()
                
            }) {
                Image(systemName: "eyedropper.full")
                    
            }
            
            
            Menu {
                
                Button(action: {

                    

                    isDraw = true
                    type = .pencil

                }) {

                    Label {

                        Text("Pencil")

                    } icon: {

                        Image(systemName: "pencil")
                    }

                }

                Button(action: {

                    isDraw = true
                    type = .pen

                }) {

                    Label {

                        Text("Pen")

                    } icon: {

                        Image(systemName: "pencil.tip")
                    }

                }

                Button(action: {

                    isDraw = true
                    type = .marker

                }) {

                    Label {

                        Text("Marker")

                    } icon: {

                        Image(systemName: "highlighter")
                    }

                }

            } label: {

                Image(systemName: "line.horizontal.3")
                    .resizable()
                    .frame(width: 15, height: 15)
            }

        }
        )
        
        .sheet(isPresented: $colorPicker) {
            ColorPickerView(showSheetView: $colorPicker, color: $color)
        }
    }
    
    
    func SaveImage(){

        

        let image = canvas.drawing.image(from: canvas.drawing.bounds, scale: 1)

        

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

//選擇顏色的畫面
struct ColorPickerView: View {
    @Binding var showSheetView: Bool
    @Binding var color : Color
    var body: some View {
        NavigationView {
            ColorPicker("Pick Color", selection: $color)
            .padding()
            .navigationBarTitle(Text("Color Picker"), displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {
                    print("Dismissing sheet view...")
                    self.showSheetView = false
                }) {
                    Text("Done").bold()
                }
                )
            
        }
    }
}

// 分享的畫面
struct ShareSheet: UIViewControllerRepresentable {
   
    var items : [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        return controller
    }
    
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            
    }
}

// 畫布
struct DrawingView : UIViewRepresentable {
    
    
    
    @Binding var canvas : PKCanvasView
    @Binding var isDraw : Bool
    @Binding var type : PKInkingTool.InkType
    @Binding var color : Color
    
    
    var ink : PKInkingTool{
        
        PKInkingTool(type, color: UIColor(color))
    }
    
    let eraser = PKEraserTool(.bitmap)
    
    func makeUIView(context: Context) -> PKCanvasView{
        
        canvas.drawingPolicy = .anyInput
        
        canvas.tool = isDraw ? ink : eraser
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        
        
        
        uiView.tool = isDraw ? ink : eraser
    }
}

// 控制登入登出畫面
struct Home : View{
    
    @State var show = false
    @State var status = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
    
    var body: some View{
        
        NavigationView{

            VStack{
                
                if self.status{
                    Homescreen()
                }
                
                else{
                    
                    ZStack{

                        NavigationLink(
                            destination: SignUp(show:self.$show),
                            isActive: self.$show,
                            label: {
                                Text("")
                            })
                            .hidden()
                        Login(show: self.$show)
                    }
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear(){
                NotificationCenter.default.addObserver(forName: NSNotification.Name("status"), object: nil, queue: .main) { (_) in
                    self.status = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
                }
            }
        }
    }
}

// 登入後的主要畫面
struct Homescreen : View {
    
    @State var show_game = false
    @State var show_classifier = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View{
        
        NavigationView{
            
            VStack{
                
                Text("Be Creative !")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.black.opacity(0.7))
                    .padding(.top)
                
                Image("brainstorm")
                    .resizable()
                    .frame(width: UIScreen.main.bounds.width / 5,height: UIScreen.main.bounds.width / 5)
                
                Button(action: {
                    show_game = true
                }) {
                
                Text("Draw a Sketch")
                    .fontWeight(.bold)
                      .foregroundColor(.black)
                      .padding(.vertical)
                      .frame(width: UIScreen.main.bounds.width - 200)
                }
                .background(Color("Color-1"))
                .cornerRadius(10)
                .padding(.top, 25)
                
                Button(action: {
                    show_classifier = true
                }) {
                
                Text("Create a Story")
                    .fontWeight(.bold)
                      .foregroundColor(.black)
                      .padding(.vertical)
                      .frame(width: UIScreen.main.bounds.width - 200)
                }
                .background(Color("Color-1"))
                .cornerRadius(10)
                .padding(.top, 25)
                            
                Button(action: {

                try! Auth.auth().signOut()
                  UserDefaults.standard.set(false, forKey: "status")
                  NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
                  
                }) {
                Text("Log Out")
                    .fontWeight(.bold)
                      .foregroundColor(.black)
                      .padding(.vertical)
                      .frame(width: UIScreen.main.bounds.width - 200)
                }
                .background(Color("Color-1"))
                .cornerRadius(10)
                .padding(.top, 25)
                
                NavigationLink(destination: CanvasView(),isActive: $show_game,label: {Text("")})
                    .hidden()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                
                NavigationLink(destination: CreateStory(),isActive: $show_classifier,label: {Text("")})
                    .hidden()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// 登入畫面
struct Login : View{
    
    @State var color = Color.black.opacity(0.7)
    @State var email = ""
    @State var pass = ""
    @State var visible = false
    @Binding var show : Bool
    @State var alert = false
    @State var error = ""
    
    var body: some View{
        
        ZStack{
            
            ZStack(alignment: .topTrailing){
                
                GeometryReader{_ in
                    
                    VStack{
                        
                        Image("painting").resizable()
                            .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100, alignment: .bottom)
                            .padding(.top, 100)
                        
                        Text("Draw Your Story")
                            .font(.title)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(self.color)
                        
                        TextField("Email",text: self.$email)
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                            .padding()
                            .background(RoundedRectangle(cornerRadius:4).stroke(self.email != "" ? Color("Color") : self.color,lineWidth: 2))
                            .padding(.top, 25)
                        
                        HStack(spacing: 15){
                            
                            VStack{
                                if self.visible{
                                    
                                    TextField("Password",text: self.$pass)
                                        .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                                }
                                else{
                                    SecureField("Password",text: self.$pass)
                                        .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                                }
                            }
                            
                            Button(action: {
                                self.visible.toggle()
                            }, label: {
                                Image(systemName: self.visible ? "eye.slash.fill":"eye.fill")
                                    .foregroundColor(self.color)
                            })
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius:4).stroke(self.pass != "" ? Color("Color") : self.color,lineWidth: 2))
                        .padding(.top, 25)
                        
                        HStack{
                            
                            Spacer()
                            
                            Button(action: {
                                self.reset()
                            }, label: {
                                Text("Forget Password")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("Color"))
                            })
                        }
                        .padding(.top,20)
                        
                        Button(action: {
                            self.verify()
                        }, label: {
                            Text("Log in")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.vertical)
                                .frame(width: UIScreen.main.bounds.width-50)
                        })
                        .background(Color("Color"))
                        .cornerRadius(10)
                        .padding(.top,25)
                    }
                    .padding(.horizontal,25)
                }
                
                Button(action: {
                    self.show.toggle()
                }, label: {
                    
                    Text("Register")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(Color("Color"))
                })
                .padding()
            }
            
            if self.alert{
                
                ErrorView(alert: self.$alert, error: self.$error)
            }
        }
        
    }
    
    func verify(){
        
        if self.email != "" && self.pass != ""{
            
            Auth.auth().signIn(withEmail: self.email, password: self.pass) { (res, err) in
                if err != nil{
                    self.error = err!.localizedDescription
                    self.alert.toggle()
                    return
                }
                print("success")
                UserDefaults.standard.set(true, forKey: "status")
                NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
            }
        }
        
        else{
            self.error = "Please fill all content"
            self.alert.toggle()
        }
    }
    
    func reset(){
        if self.email != ""{
            Auth.auth().sendPasswordReset(withEmail: self.email) { (err) in
                if err != nil{
                    self.error = err!.localizedDescription
                    self.alert.toggle()
                    return
                }
              
                self.error = "RESET"
                self.alert.toggle()
            }
        }
        else{
            self.error = "Email Id is empty"
            self.alert.toggle()
        }
    }
}

// 申請帳號
struct SignUp : View{
    
    @State var color = Color.black.opacity(0.7)
    @State var email = ""
    @State var pass = ""
    @State var repass = ""
    @State var visible = false
    @State var revisible = false
    @Binding var show : Bool
    @State var alert = false
    @State var error = ""
    
    var body: some View{
        
        ZStack{
            
            ZStack(alignment: .top){
                
                GeometryReader{_ in
                    
                    VStack{
                        
                        Image("painting").resizable()
                            .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100, alignment: .bottom)
                        
                        Text("Draw Your Story")
                            .font(.title)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(self.color)
                        
                        TextField("Email",text: self.$email)
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                            .padding()
                            .background(RoundedRectangle(cornerRadius:4).stroke(self.email != "" ? Color("Color") : self.color,lineWidth: 2))
                            .padding(.top, 25)
                        
                        HStack(spacing: 15){
                            
                            VStack{
                                if self.visible{
                                    
                                    TextField("Password",text: self.$pass)
                                        .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                                }
                                else{
                                    SecureField("Password",text: self.$pass)
                                        .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                                }
                            }
                            
                            Button(action: {
                                self.visible.toggle()
                            }, label: {
                                Image(systemName: self.visible ? "eye.slash.fill":"eye.fill")
                                    .foregroundColor(self.color)
                            })
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius:4).stroke(self.pass != "" ? Color("Color") : self.color,lineWidth: 2))
                        .padding(.top, 25)
                        
                        HStack(spacing: 15){
                            
                            VStack{
                                if self.revisible{
                                    
                                    TextField("Re-enter",text: self.$repass)
                                        .autocapitalization(.none)
                                }
                                else{
                                    SecureField("Re-enter",text: self.$repass)
                                        .autocapitalization(.none)
                                }
                            }
                            
                            Button(action: {
                                self.revisible.toggle()
                            }, label: {
                                Image(systemName: self.revisible ? "eye.slash.fill":"eye.fill")
                                    .foregroundColor(self.color)
                            })
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius:4).stroke(self.repass != "" ? Color("Color") : self.color,lineWidth: 2))
                        .padding(.top, 25)
                        
                        Button(action: {
                            self.register()
                        }, label: {
                            Text("Resgister")
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .foregroundColor(.white)
                                .padding(.vertical)
                                .frame(width: UIScreen.main.bounds.width-50)
                        })
                        .background(Color("Color"))
                        .cornerRadius(10)
                        .padding(.top,25)
                    }
                    .padding(.horizontal,25)
                }
            }
            
            if self.alert{
                
                ErrorView(alert: self.$alert, error: self.$error)
            }
        }
    }
    
    func register(){
        if self.email != ""{
            if self.pass == self.repass{
                Auth.auth().createUser(withEmail: self.email, password: self.pass) { (res, err) in
                    
                    if err != nil{
                        self.error = err!.localizedDescription
                        self.alert.toggle()
                        return
                    }
                      
                    print("success")
                      
                    UserDefaults.standard.set(true, forKey: "status")
                    NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
                }
            }
            else{
                self.error = "Password mismatch"
                self.alert.toggle()
            }
        }
        
        else{
            self.error = "Please fill all the contents properly"
            self.alert.toggle()
        }
    }
}

// 跑出 error message 的畫面
struct ErrorView : View {
      
      @State var color = Color.black.opacity(0.7)
      @Binding var alert : Bool
      @Binding var error : String
      
      var body: some View{
          
          GeometryReader{_ in
              
            VStack{

                  Text(self.error == "RESET" ? "Password reset link has been sent successfully" : self.error)
                    .fontWeight(.bold)
                    .foregroundColor(self.color)
                    .padding(.top)
                    .padding(.horizontal, 25)
                  
                  Button(action: {
                      
                      self.alert.toggle()
                      
                  }) {
                      
                      Text(self.error == "RESET" ? "Ok" : "Cancel")
                          .fontWeight(.bold)
                          .foregroundColor(.white)
                          .padding(.vertical)
                          .frame(width: UIScreen.main.bounds.width - 120)
                  }
                  .background(Color("Color"))
                  .cornerRadius(10)
                  .padding(.top, 25)
                  
              }
              .padding(.vertical,25)
              .frame(width: UIScreen.main.bounds.width)
              .background(Color.white)
              .cornerRadius(15)
        
          }
          .background(Color.black.opacity(0.7).edgesIgnoringSafeArea(.all))
      }
  }
