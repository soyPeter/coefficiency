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

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class Delete__ENTITY__UseCaseTest {

    @Mock
    private __ENTITY__CommandAction mockCommandAction;

    private Delete__ENTITY__UseCase useCase;

    @BeforeEach
    void setUp() {
        useCase = new Delete__ENTITY__UseCase(mockCommandAction);
    }

    @Test
    @DisplayName("Should soft delete __ENTITY__")
    void shouldSoftDelete() {
        __ENTITY__ entity = __ENTITY__.create("Test", "Desc");
        when(mockCommandAction.findById(entity.id())).thenReturn(Optional.of(entity));

        useCase.execute(entity.id(), "tester");

        verify(mockCommandAction).save(argThat(__ENTITY__::deleted));
    }

    @Test
    @DisplayName("Should throw when __ENTITY__ not found")
    void shouldThrowWhenNotFound() {
        when(mockCommandAction.findById("unknown")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute("unknown", "tester"))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
