import UIKit

struct Character: CustomStringConvertible {
    let id: Int
    let name: String
    
    var description: String {
        "ID: \(id) | Character: \(name)"
    }
}

struct RickAndMortyService {
    
    let rickAndMortyParser = RickAndMortyParser()
    let rickAndMortyAPI = RickAndMortyAPI()
    
    func getCharacters(completionHandler: @escaping ([Character]) -> Void) {
        rickAndMortyAPI.requestCharacters { (charactersDictionary) in
            let characters = charactersDictionary.compactMap{ rickAndMortyParser.parseCharacterDictionary(dictionary: $0) }
            completionHandler(characters)
        }
    }
    
    func getCharactersResult(completionHandler: @escaping ([Character]) -> Void) {
        rickAndMortyAPI.requestCharactersResult { (result) in
            
        }
    }
    
}

struct RickAndMortyParser {
    
    func parseCharacterDictionary(dictionary: [String: Any]) -> Character? {
        guard let id = dictionary["id"] as? Int,
              let name = dictionary["name"] as? String
        else { return nil }
        
        return Character(id: id, name: name)
    }
    
}

struct RickAndMortyAPI {
    
    func requestCharacters(completionHandler: @escaping ([[String: Any]]) -> Void) {
        let url = URL(string: "https://rickandmortyapi.com/api/character")!
        
        typealias WebCharacter = [String: Any]
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any],
                  let charactersDictionary = json["results"] as? [WebCharacter]
            else {
                completionHandler([])
                return
            }
            completionHandler(charactersDictionary)
        }
        .resume()
    }
    
    func requestCharactersResult(completionHandler: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let url = URL(string: "https://rickandmortyapi.com/api/character")!
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any],
                  let charactersDictionary = json["results"] as? [[String: Any]]
            else {
                completionHandler(Result.failure(error!))
                return
            }
            completionHandler(Result.success(charactersDictionary))
        }
        .resume()
    }
    
}

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let rickAndMortyService = RickAndMortyService()
    
    var characters: [Character] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.isHidden = self.characters.isEmpty
                self.activityIndicator.isHidden = !self.characters.isEmpty
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        
        tableView.isHidden = self.characters.isEmpty
        activityIndicator.isHidden = !self.characters.isEmpty
        
        rickAndMortyService.getCharacters { characters in
            self.characters = characters
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
        
        let character = characters[indexPath.row]
        
        cell.textLabel?.text = character.name
        cell.detailTextLabel?.text = "\(character.id)"
        
        return cell
    }
    
}

