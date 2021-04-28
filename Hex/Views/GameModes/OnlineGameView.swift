//
//  OnlineGameView.swift
//  Hex
//
//  Created by Duong Pham on 3/16/21.
//

import SwiftUI
import UIKit

struct OnlineGameView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var audioManager: AudioManager
    var modalManager = ModalManager()

    @State var showResult = false
    @State private var showSettingsForPhone = false
    @State private var showSettingsForPad = false
    @ObservedObject var hexGame: OnlineGame
    @AppStorage("musicOn") var musicOn = false
    @AppStorage("soundOn") var soundOn = false
    @AppStorage("firstName") var firstName = ""
    var isIpad = UIDevice.current.userInterfaceIdiom == .pad
    
    let red = Color(red: 0.9296875, green: 0.46, blue: 0.453)
    let blue = Color(red:0.39, green:0.55, blue:0.894)
    let black = Color.black
    let hunterGreen = Color(red: 0.15625, green: 0.3125, blue: 0.1796875, opacity: 0.5)
    private let titleColor = Color(red: 0.82422, green: 0.37891, blue: 0.207, opacity: 1)
    let backgroundColor = Color(red: 0.83984, green: 0.90625, blue: 0.7265625, opacity: 1)
    let buttonColor = Color(red: 0.1758, green: 0.515625, blue: 0.53901, opacity: 1)
    @State private var showNotice = false
    
    var body: some View {
        let buttonFontSize: CGFloat = isIpad ? 60 : 30
        let gameTitle: CGFloat = isIpad ? 30 : 15
        let playerTurnFontSize: CGFloat = isIpad ? 50 : 25
        
        let imageFrame : CGFloat = isIpad ? 60 : 40
        
        if !hexGame.ready {
            GeometryReader { geometry in
                Rectangle().foregroundColor(backgroundColor).ignoresSafeArea().zIndex(-2)
                    .onAppear{
                        audioManager.playMusic("musicBox", type: "mp3")
                        showResult = false
                    }
                    .onDisappear {
                        audioManager.stopMusic("musicBox", type: "mp3")
                    }
                ZStack {
                    VStack {
                        ZStack {
                            Rectangle().ignoresSafeArea().foregroundColor(hunterGreen)
                            HStack {
                                Text("Back").font(Font.custom("PressStart2P-Regular", size: geometry.size.width / buttonFontSize))
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .onTapGesture {
                                        audioManager.playSound("MouseClick", type: "mp3")
                                        hexGame.exitMatch()
                                        viewRouter.currentScreen = .welcome
                                    }
                                
                                Image(systemName: "gearshape").imageScale(.large).foregroundColor(.white)
                                    .onTapGesture {
                                        if !isIpad {
                                            if modalManager.modal.position == .closed {
                                                showSettingsForPhone = true
                                                self.modalManager.peekModal()
                                            }
                                        } else {
                                            showSettingsForPad = !showSettingsForPad
                                        }
                                        audioManager.playSound("MouseClick", type: "mp3")
                                    }.onAppear {
                                        self.modalManager.newModal(position: .closed) {
                                            onlineSettingsView().environmentObject(audioManager)
                                        }
                                    }
                                    .popover(isPresented: $showSettingsForPad) {
                                        onlineSettingsView().environmentObject(audioManager)                                    }
                                    .padding()
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.width / gameTitle, alignment: .topLeading)
                        .padding(.bottom)
                        
                        HStack() {
                            if hexGame.localPlayerAvatar != nil {
                                Image(uiImage: hexGame.localPlayerAvatar!)
                                    .clipShape(Circle())
                                    .frame(width: imageFrame, height: imageFrame, alignment: .center)
                            } else {
                                Image(hexGame.localPlayer == 1 ? "redava" : "guestava")
                                    .frame(width: imageFrame, height: imageFrame, alignment: .center)
                                    .scaleEffect(isIpad ? 60/673 : 40/673)
                            }

                            Text(hexGame.localPlayer == hexGame.board.playerTurn ? "Your turn" : "\(hexGame.remotePlayerName)'s turn")
                                .padding(.horizontal)
                                .font(Font.custom("PressStart2P-Regular", size: isIpad ?  20 : 10))
                                .foregroundColor(hexGame.localPlayer == 1 ? blue : red)
                                .frame(width: geometry.size.width / 2, alignment: .center)
                            
                            if hexGame.remotePlayerAvatar != nil {
                                Image(uiImage: hexGame.remotePlayerAvatar!)
                                    .clipShape(Circle())
                                    .frame(width: imageFrame, height: imageFrame, alignment: .center)
                            } else {
                                Image(hexGame.localPlayer == 1 ? "guestava" : "redava")
                                    .scaleEffect(isIpad ? 60/673 : 40/673)
                                    .frame(width: imageFrame, height: imageFrame, alignment: .center)
                            }
                        }
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.black)
                        
                        ZStack {
                            HexGrid(hexGame.cellValues, cols: hexGame.board.size) { cell in
                                CellView(cell: cell).onTapGesture {
                                    audioManager.playSound("move", type: "wav")
                                    if !hexGame.gameEnded { // only when game has not ended
                                        hexGame.play(cellId: cell.id)
                                    }
                                }
                            }
                            .onChange(of: hexGame.gameEnded, perform: { value in
                                if hexGame.gameEnded {
                                    audioManager.playSound(hexGame.result == "You lose" ? "lose" : "win", type: "mp3")
                                }
                            })
                            .rotationEffect(Angle(degrees: 90))
                            .scaleEffect(isIpad ? 0.9 : 1)
                            .onReceive(self.hexGame.$board, perform: { newValue in
                                if newValue.winner != 0 {
                                    showResult = true
                                }
                            })
                            .popup(isPresented: $showResult) {
                                ZStack {
                                    resultReport(game: hexGame, showResult: showResult)
                                }
                            }
                        }
                        newGameButton(game: hexGame, buttonFontSize: geometry.size.width / buttonFontSize, showResult: !showResult) // disabled when result view pop up
                        .foregroundColor(!showResult ? .blue : .gray)
                        .padding()
                    }
                    ModalAnchorView().environmentObject(modalManager)
                }
            }
        }
        else {
            LoadingView(game: hexGame)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { timer in
                        showNotice = true
                        timer.invalidate()
                        print("start counting")
                   }
                }
                .alert(isPresented: $showNotice) {
                    Alert(title: Text("No match found"), message: Text("Yikes, seems like you're the only on online at this moment. Please exit and try again"), primaryButton:
                            .default(Text("OK"), action: {
                                hexGame.exitMatch()
                                viewRouter.currentScreen = .welcome
                            })
                    , secondaryButton: .cancel())
            }
        }
    }
}



struct onlineSettingsView: View {
    @State private var showAlert: Bool = false
    private let lightCyan: Color = Color(red: 0.8555, green: 0.984375, blue: 0.9961, opacity: 0.8)
    private let queenBlue = Color(red: 0.26953, green: 0.41, blue: 0.5625)
    private let headerFontSize: CGFloat = 15
    private let wildBlueYonder = Color(red: 0.71875, green: 0.71875, blue: 0.8164, opacity: 1)
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        HStack {
            Section(header: Text("Sound")) {
                Button {
                    audioManager.toggleSound()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).frame(width: 50, height: 50, alignment: .center) .foregroundColor(lightCyan)
                        Image(systemName: audioManager.soundOn ? "speaker.wave.3" : "speaker").imageScale(.large)
                    }
                }
            }

            Section(header: Text("Music")) {
                Button {
                    audioManager.toggleMusic()
                    if audioManager.musicOn {
                        audioManager.playMusic("musicBox", type: "mp3")
                    } else {
                        audioManager.stopMusic("musicBox", type: "mp3")
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).frame(width: 50, height: 50, alignment: .center)
                            .foregroundColor(lightCyan)
                        Image(systemName: audioManager.musicOn ? "music.note" : "play.slash").imageScale(.large)
                    }
                }
            }
        }
        .foregroundColor(queenBlue)
        .padding()
        .font(Font.custom("KronaOne-Regular", size: headerFontSize))
        .background(wildBlueYonder)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        OnlineGameView(hexGame: OnlineGame()).environmentObject(AudioManager())
    }
}
