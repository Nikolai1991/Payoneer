package com.example.common.model;

import javax.persistence.*;
import java.util.Date;

@Entity
@Table(name = "Charges")
public class Charge {

    @Id()
    @Column(name = "Charge_ID")
    private Integer Charge_ID;

    @Column(name = "Account_ID")
    private Integer Account_ID;

    @Column(name = "Charge_Currency")
    private String Charge_Currency;

    @Column(name = "Charge_status")
    private Integer Charge_status;

    @Column(name = "Charge_Amount")
    private Double Charge_Amount;


    public Integer getCharge_ID() {
        return Charge_ID;
    }

    public void setCharge_ID(Integer charge_ID) {
        Charge_ID = charge_ID;
    }

    public Integer getAccount_ID() {
        return Account_ID;
    }

    public void setAccount_ID(Integer account_ID) {
        Account_ID = account_ID;
    }

    public String getCharge_Currency() {
        return Charge_Currency;
    }

    public void setCharge_Currency(String charge_Currency) {
        Charge_Currency = charge_Currency;
    }

    public Integer getCharge_status() {
        return Charge_status;
    }

    public void setCharge_status(Integer charge_status) {
        Charge_status = charge_status;
    }

    public Double getCharge_Amount() {
        return Charge_Amount;
    }

    public void setCharge_Amount(Double charge_Amount) {
        Charge_Amount = charge_Amount;
    }
}
