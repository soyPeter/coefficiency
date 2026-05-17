package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.domain.actions.__ENTITY__CommandAction;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class Get__ENTITY__ByIdUseCaseTest {

    @Mock
    private __ENTITY__CommandAction mockCommandAction;

    private Get__ENTITY__ByIdUseCase useCase;

    @BeforeEach
    void setUp() {
        useCase = new Get__ENTITY__ByIdUseCase(mockCommandAction);
    }

    @Test
    @DisplayName("Should return __ENTITY__ when found")
    void shouldReturnEntity() {
        __ENTITY__ entity = __ENTITY__.create("Test", "Desc");
        when(mockCommandAction.findById(entity.id())).thenReturn(Optional.of(entity));

        Optional<__ENTITY__> result = useCase.execute(entity.id());

        assertThat(result).isPresent();
        assertThat(result.get().name()).isEqualTo("Test");
    }
}
