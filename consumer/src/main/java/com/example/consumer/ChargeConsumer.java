package com.example.consumer;

import com.example.common.model.Charge;
import com.example.common.model.ShadowCharge;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.MessageHeaders;
import org.springframework.messaging.handler.annotation.Headers;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Random;

@Service
public class ChargeConsumer {
    static class CurrencyTuple{
        final String currency;
        final float rate;

        CurrencyTuple(String currency, float rate) {
            this.currency = currency;
            this.rate = rate;
        }
    }

    final static List<CurrencyTuple> currencies = Arrays.asList(new CurrencyTuple("GBP",0.8f),new CurrencyTuple("EUR",0.89f));
    final static Random random = new Random();

    static CurrencyTuple getCurrency(){
        return currencies.get(random.nextInt(currencies.size()));
    }

@Autowired ShadowChargeRepository repository;
    private static final Logger LOG = LoggerFactory.getLogger(ChargeConsumer.class);

    @KafkaListener(topics = "${app.topic:charges}")
    public void receive(@Payload Charge data,
                        @Headers MessageHeaders headers) {
        LOG.info("received data='{}'", data);
        ShadowCharge shadowCharge = new ShadowCharge();
        shadowCharge.setAccount_ID(data.getAccount_ID());
        shadowCharge.setCharge_ID(data.getCharge_ID());
        shadowCharge.setCharge_status(data.getCharge_status());
        CurrencyTuple currencyTuple = getCurrency();
        shadowCharge.setCharge_Currency(currencyTuple.currency);
        shadowCharge.setCharge_Amount(data.getCharge_Amount() * currencyTuple.rate);

        repository.save(shadowCharge);
    }

}
