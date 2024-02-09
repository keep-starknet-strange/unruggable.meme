import { PrimaryButton, SecondaryButton } from 'src/components/Button'
import { Row } from 'src/theme/components/Flex'

export interface FormPageProps {
  next: () => void
  previous?: () => void
}

export type LastFormPageProps = Omit<FormPageProps, 'next'>

interface SubmitProps {
  previous: FormPageProps['previous']
  nextText?: string
  onNext?: () => void
  disableNext?: boolean
}

export function Submit({ previous, onNext, nextText = 'Next', disableNext = false }: SubmitProps) {
  return (
    <Row gap="16">
      {!!previous && (
        <SecondaryButton onClick={previous} flex="1">
          Previous
        </SecondaryButton>
      )}
      <PrimaryButton type={onNext ? undefined : 'submit'} onClick={onNext} disabled={disableNext} flex="1">
        {nextText}
      </PrimaryButton>
    </Row>
  )
}
