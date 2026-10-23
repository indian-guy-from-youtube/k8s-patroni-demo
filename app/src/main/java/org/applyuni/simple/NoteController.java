package org.applyuni.simple;

import org.springframework.web.bind.annotation.*;

import java.net.InetAddress;
import java.util.*;

@RestController
public class NoteController {
    private final NoteRepository repo;
    public NoteController(NoteRepository repo){
        this.repo = repo;
    }
    @GetMapping("/notes")
    public List<Note> all(){
        return repo.findAll();
    }
    @PostMapping("/notes")
    public Note addNote(@RequestBody Note n){
        n.setId(null);
        return repo.save(n);
    }
    @DeleteMapping("/notes/{id}")
    public void delete(@PathVariable Long id){
        repo.deleteById(id);
    }
    @GetMapping("/whoami")
    public Map<String, String> whoami() throws Exception {
        return Map.of("pod", InetAddress.getLocalHost().getHostName());
    }
}
