//
//  ViewController.swift
//  PDFDemo
//
//  Created by Ver on 2025/1/2.
//

import UIKit
import PDFKit
import Alamofire
import SnapKit
import Combine
import PencilKit

class ViewController: UIViewController {
    
    let pdfView = PDFView()
    
    let thunbnailView: PDFThumbnailView = PDFThumbnailView()
    
    private var cancelables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pdfView)
        pdfView.layer.borderColor = UIColor.red.cgColor
        pdfView.layer.borderWidth = 1
        pdfView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-100)
        }
        
        ///用來自動縮放PDF檔案尺寸
        pdfView.autoScales = true
        ///用來一頁一頁的滑動
        pdfView.usePageViewController(true)
        let action = PDFActionGoTo()
        
        PDFManager.shared.downloadPDF()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    break
                }
            } receiveValue: { url in
                self.pdfView.document = PDFDocument(url: url)
                self.createThumbnails()
            }
            .store(in: &cancelables)
    }
    
    private func createThumbnails() {
        view.addSubview(thunbnailView)
        thunbnailView.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.height.equalTo(80)
            $0.leading.trailing.equalToSuperview()
        }
        
        view.layoutIfNeeded()
        thunbnailView.pdfView = pdfView
        thunbnailView.backgroundColor = .darkGray
        thunbnailView.layoutMode = .horizontal
    }
}

//https://www.pwfa.org.tw/ezfiles/23/1023/img/77/199441861.pdf
class PDFManager {
    static let shared = PDFManager()
    
    func downloadPDF() -> AnyPublisher<URL, Error> {
        let subject: PassthroughSubject<URL, Error> = .init()
        let url = URL(string: "https://www.csie.ntu.edu.tw/~lyuu/theses/thesis_j94922029.pdf")!
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("PDFTest.pdf")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        AF.download(url, to: destination).response { response in
            if let error = response.error {
                subject.send(completion: .failure(error))
                return
            }
            
            if let fileURL = response.fileURL {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    subject.send(fileURL)
                    subject.send(completion: .finished)
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
}
