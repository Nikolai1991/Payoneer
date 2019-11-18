package com.example.producer;

import com.example.common.model.Charge;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
@Service
public class ChargeProducer {
    private static final Logger logger = LoggerFactory.getLogger(ChargeProducer.class);
    @Value("${app.topic:charges}")
    private String topic;

    @Autowired
    private KafkaTemplate<String,Charge> kafkaTemplate;

    static ExecutorService executorService = Executors.newFixedThreadPool(10);
    public  void doPage(Page<Charge> chargePage){

        executorService.submit(()->{
           chargePage.forEach(c->{
               Message<Charge> message = MessageBuilder
                       .withPayload(c)
                       .setHeader(KafkaHeaders.TOPIC, topic)
                       .build();

               kafkaTemplate.send(message);

               logger.info(String.format("%d - %f (%s)",c.getAccount_ID(),c.getCharge_Amount(),c.getCharge_Currency()));
           });
        });
    }
}
