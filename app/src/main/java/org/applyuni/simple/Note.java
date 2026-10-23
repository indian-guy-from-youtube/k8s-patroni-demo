package org.applyuni.simple;

import jakarta.persistence.*;

@Entity
public class Note {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String text;

    public Long getId(){return  id;}
    public void setId(Long ig){this.id = id;}
    public String getText(){return text;}
    public void setText(){this.text = text;}
}
