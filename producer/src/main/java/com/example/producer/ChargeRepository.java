package com.example.producer;

import com.example.common.model.Charge;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.PagingAndSortingRepository;

public interface ChargeRepository extends PagingAndSortingRepository<Charge,Integer> {
}
