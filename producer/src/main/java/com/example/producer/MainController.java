package com.example.producer;

import com.example.common.model.Charge;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.Random;

@Controller
@RequestMapping(path = "/producer")
public class MainController {
    @Autowired
    ChargeRepository chargeRepository;

    @Autowired
    ChargeProducer producer;

    Random random = new Random();

    static class ProducerSlice{
        public final long offset;
        public final  long size;
        public final long total;

        ProducerSlice(Page page){
            total= page.getTotalElements();
            size = page.getSize();
            offset = page.getNumber();
        }
    }

    @PostMapping
    public @ResponseBody ProducerSlice startProducer(@RequestParam int count){
        Page<Charge> charges= chargeRepository.findAll(PageRequest.of(random.nextInt(10),count));
        ProducerSlice prod = new ProducerSlice(charges);

        producer.doPage(charges);

        return prod;
    }
}
