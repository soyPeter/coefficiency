package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.infra.data.dto.Create__ENTITY__Req;
import __PACKAGE__.__SERVICE__.domain.actions.__ENTITY__CommandAction;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class Create__ENTITY__UseCaseTest {

    @Mock
    private __ENTITY__CommandAction mockCommandAction;

    private Create__ENTITY__UseCase useCase;

    @BeforeEach
    void setUp() {
        useCase = new Create__ENTITY__UseCase(mockCommandAction);
    }

    @Test
    @DisplayName("Should create __ENTITY__ with valid data")
    void shouldCreate() {
        Create__ENTITY__Req request = new Create__ENTITY__Req("Test Name", "Test Description");

        __ENTITY__ result = useCase.execute(request);

        assertThat(result).isNotNull();
        assertThat(result.name()).isEqualTo("Test Name");
        assertThat(result.description()).isEqualTo("Test Description");
        assertThat(result.deleted()).isFalse();
        verify(mockCommandAction).save(any(__ENTITY__.class));
    }
}
