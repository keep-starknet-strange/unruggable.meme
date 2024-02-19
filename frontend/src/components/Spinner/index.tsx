import * as styles from './styles.css'

interface SpinnerProps extends React.SVGProps<SVGSVGElement> {
  fill?: string
}

const Spinner = (props: SpinnerProps) => (
  <svg viewBox="0 0 50 50" className={styles.spinner} {...props}>
    <circle className={styles.dashSpinner} cx="25" cy="25" r="20" fill="none" strokeWidth="4" />
  </svg>
)

export default Spinner
