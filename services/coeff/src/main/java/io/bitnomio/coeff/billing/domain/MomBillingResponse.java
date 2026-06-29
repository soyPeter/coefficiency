package io.bitnomio.coeff.billing.domain;

import java.util.List;

// REQ-MOM-DOMAIN-002
public record MomBillingResponse(int year, List<MomBillingRow> rows) {}
