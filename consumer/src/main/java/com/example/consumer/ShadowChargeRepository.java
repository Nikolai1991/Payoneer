package com.example.consumer;

import com.example.common.model.ShadowCharge;
import org.springframework.data.repository.PagingAndSortingRepository;

public interface ShadowChargeRepository extends PagingAndSortingRepository<ShadowCharge,Integer> {
}
