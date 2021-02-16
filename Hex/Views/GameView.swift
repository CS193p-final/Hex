//
//  GameView.swift
//  Hex
//
//  Created by Duong Pham on 2/14/21.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var hexGame = GameViewModel()
    
    var body: some View {
        HexGrid(hexGame.cellValues) { cell in
            CellView(cell: cell)
                .onTapGesture {
                    hexGame.play(cellId: cell.id)
                    print(hexGame.result)
                }
        }
    }
    
    func appendArray() -> [Cell]{
        var cellArray = [Cell]()
        for index in (0..<121) {
            cellArray.append(Cell(id: index))
        }
        return cellArray
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
