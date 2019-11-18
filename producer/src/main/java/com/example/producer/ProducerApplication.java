package com.example.producer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;

@SpringBootApplication
@EntityScan( basePackages = {"com.example.common"} )
public class ProducerApplication {

    public static void main(String[] args) {

        SpringApplication.run(ProducerApplication.class, args);
    }

}
